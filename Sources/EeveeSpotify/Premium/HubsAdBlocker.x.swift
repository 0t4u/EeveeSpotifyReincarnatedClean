import Orion
import Foundation

// HUB JSON component structure (from open-source HubFramework):
// Each component dict has:
//   "component": {"namespace": "mobile", "name": "display-ad-card"}
//     — OR in some versions just a string "mobile:display-ad-card"
//   "id": "some-identifier"
//   "metadata": {...}
//   "logging": {...}
//   "body": [...] (child components)
//   "header": {...}
//   "overlays": [...]
//   "sections": [...]
//
// Known ad component identifiers found in Spotify 9.1.x binary:
//   mobile-display-ad-card          (namespace: mobile, name: display-ad-card)
//   mobile-ads-display-ad-element   (namespace: mobile-ads, name: display-ad-element)
//   mobile-ads-fullbleed-display-card
//   mobile-ads-embedded-npv-display-card
//   native-ad-home-shelf
//   com.spotify.service.marquee

// Strips ad components from HUB JSON (home/browse/search) before the builder
// renders them. Known ad ids: mobile-display-ad-card, mobile-ads-display-ad-element,
// mobile-ads-fullbleed-display-card, native-ad-home-shelf, com.spotify.service.marquee.

struct AdBlockerGroup: HookGroup { }

class HubsAdBlocker: ClassHook<NSObject> {
    typealias Group = AdBlockerGroup
    static let targetName: String = "HUBViewModelBuilderImplementation"

    // Bare "ad"/"ads" intentionally absent: as substrings they hit real shelf ids
    // (made-for-you, release-radar). Matched only against structural fields, never titles.
    private static let hardAdKeywords: [String] = [
        "sponsored", "upsell", "campaign", "promoted", "premium-upsell",
        "billboard", "interstitial", "marquee",
        "leavebehind", "leave-behind", "displayad", "display-ad", "fullbleed",
        "full-bleed", "leaderboard", "advertisement", "sponsor", "native-ad",
        "mobile-ads", "on-surface", "onsurface", "search-ad", "home-ad",
        "sponsored-content", "sponsored-ad", "ad-card", "native-ad-home-shelf",
        "sponsored-shelf", "sponsored-row", "ad-shelf", "ad-row", "sponsored-item",
        "ad-item", "upgrade-component",
        "mobile-display-ad-card", "mobile-ads-display-ad-element"
    ]

    private static let promotionalIntentKeywords: [String] = [
        "premium", "upgrade", "offer", "marketing", "promo", "promotion",
        "subscribe", "subscription",
    ]

    private static let promotionalSurfaceKeywords: [String] = [
        "banner", "card", "popup", "pop-up", "sheet", "overlay", "component",
        "message",
    ]

    private static let nestedComponentKeys: Set<String> = [
        "children", "rows", "body", "header", "overlays", "sections",
        "components", "items", "elements", "cards", "slots", "content",
    ]

    private static func containsAdKeyword(_ str: String) -> Bool {
        let lower = str.lowercased()
        if hardAdKeywords.contains(where: { lower.contains($0) }) { return true }
        let hasPromotionalIntent = promotionalIntentKeywords.contains { lower.contains($0) }
        let hasPromotionalSurface = promotionalSurfaceKeywords.contains { lower.contains($0) }
        return hasPromotionalIntent && hasPromotionalSurface
    }

    private func isAdComponent(_ component: [String: Any]) -> Bool {
        if let componentDict = component["component"] as? [String: Any] {
            let ns = componentDict["namespace"] as? String ?? ""
            let name = componentDict["name"] as? String ?? ""
            if HubsAdBlocker.containsAdKeyword(ns) { return true }
            if HubsAdBlocker.containsAdKeyword(name) { return true }
            if HubsAdBlocker.containsAdKeyword("\(ns):\(name)") { return true }
        }
        // plain string form, e.g. "mobile:display-ad-card"
        if let componentStr = component["component"] as? String {
            if HubsAdBlocker.containsAdKeyword(componentStr) { return true }
        }

        if let id = component["id"] as? String, HubsAdBlocker.containsAdKeyword(id) { return true }
        if let type_ = component["type"] as? String, HubsAdBlocker.containsAdKeyword(type_) { return true }

        if let metadata = component["metadata"] as? [String: Any] {
            if metadata["ad"] as? Bool == true { return true }
            if metadata["is_ad"] as? Bool == true { return true }
            if metadata["is_sponsored"] as? Bool == true { return true }
            for key in metadata.keys where HubsAdBlocker.containsAdKeyword(key) { return true }
        }

        if let logging = component["logging"] as? [String: Any] {
            if let logType = logging["type"] as? String, HubsAdBlocker.containsAdKeyword(logType) { return true }
            for key in logging.keys where HubsAdBlocker.containsAdKeyword(key) { return true }
        }

        if let custom = component["custom"] as? [String: Any] {
            for key in custom.keys where HubsAdBlocker.containsAdKeyword(key) { return true }
        }

        // Display strings (title/subtitle/text) are NOT matched — real content
        // ("Billboard Hot 100", "Ticket to Ride") trips the keywords.
        return false
    }

    private func filterComponent(_ component: [String: Any]) -> [String: Any]? {
        guard !isAdComponent(component) else { return nil }

        var filtered = component
        for key in HubsAdBlocker.nestedComponentKeys {
            if let nested = filtered[key] as? [String: Any] {
                if let nestedFiltered = filterComponent(nested) {
                    filtered[key] = nestedFiltered
                } else {
                    filtered.removeValue(forKey: key)
                }
                continue
            }

            guard let nestedArray = filtered[key] as? [Any] else { continue }
            var sawDictionary = false
            let array = nestedArray.compactMap { item -> Any? in
                guard let dictionary = item as? [String: Any] else { return item }
                sawDictionary = true
                return filterComponent(dictionary)
            }
            if sawDictionary {
                filtered[key] = array
            }
        }
        return filtered
    }

    private func filterComponents(_ components: [[String: Any]]) -> [[String: Any]] {
        components.compactMap { filterComponent($0) }
    }

    func addJSONDictionary(_ dictionary: NSDictionary?) {
        guard let mutableDict = dictionary as? [String: Any] else {
            orig.addJSONDictionary(dictionary)
            return
        }

        // The builder can receive a materialized ad component directly, not
        // only a page containing one. Drop it before UIKit gets a chance to
        // render the card.
        guard let filtered = filterComponent(mutableDict) else {
            NSLog("[EeveeSpotify][AdBlock] dropped a top-level HUB ad component")
            return
        }

        orig.addJSONDictionary(filtered as NSDictionary)
    }
}

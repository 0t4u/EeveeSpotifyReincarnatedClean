import Foundation

enum ListeningActivityPrivacyPolicy {
    // This key is written into the same NSUserDefaults suite as the native
    // setting. Spotify creates separate local-settings suites per account, so
    // the latch follows that account instead of being a tweak-wide switch.
    static let latchKey = "com.eeveespotify.listening-activity-disabled"

    private static let exactKeys: Set<String> = [
        "publish-activity",
        "publishListeningActivity",
        "shareMobileRealTimeListeningActivity",
    ]

    static func isListeningActivityKey(_ key: String) -> Bool {
        let normalized = key.replacingOccurrences(of: "_", with: "-").lowercased()
        return exactKeys.contains(key)
            || exactKeys.contains(where: {
                let candidate = $0.replacingOccurrences(of: "_", with: "-").lowercased()
                return normalized == candidate || normalized.hasSuffix(".\(candidate)")
            })
    }

    static func boolValue(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        if let value = value as? NSString {
            switch value.lowercased {
            case "1", "true", "yes", "on": return true
            case "0", "false", "no", "off": return false
            default: return nil
            }
        }
        if let value = value as? String {
            switch value.lowercased() {
            case "1", "true", "yes", "on": return true
            case "0", "false", "no", "off": return false
            default: return nil
            }
        }
        return nil
    }

    static func shouldForceOff(latchedOff: Bool, storedValue: Any?) -> Bool {
        latchedOff || boolValue(storedValue) == false
    }

    static func shouldRejectWrite(
        latchedOff: Bool,
        storedValue: Any?,
        requestedValue: Any?
    ) -> Bool {
        // A nil/non-boolean write is also rejected after OFF, so a settings
        // refresh cannot remove the value and immediately re-enable sending.
        let requestsOff = boolValue(requestedValue) == false
        return !requestsOff && (latchedOff || boolValue(storedValue) == false)
    }
}

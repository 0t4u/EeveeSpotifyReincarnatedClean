import Foundation

struct ServerSidedFeaturePolicy {
    struct RemoteFlag: Equatable {
        let scope: String
        let name: String
    }

    // These values are real account entitlements. Spoofing them only exposes
    // incomplete UI; Spotify's backend still rejects the operation.
    static let serverAuthoritativeAccountAttributes: Set<String> = [
        "offline",
        "can-use-offline",
        "has-offline-state",
        "max-offline-downloads-per-device",
        "max-offline-tracks",
        "offline-backup",
        "lyrics-offline",
        "very-high-bitrate",
        "audio-quality",
        "social-session",
        "social-session-free-tier",
        "jam-social-session",
    ]

    // Hide only remote/Premium Jam hosting. Spotify's separate in-person join
    // and free-user hosting flag remains controlled by the live configuration.
    static let premiumGatedJamEntryPoint = RemoteFlag(
        scope: "ios-sociallistening-configuration-impl",
        name: "premium_gated_start_jam_buttons_enabled"
    )

    // These UI assignments belong to the current Spotify build/cohort. A
    // bundled Premium snapshot must not force friend activity or replace the
    // live Now Playing cover-art behavior.
    private static let liveConfigurationAssignmentScopes: Set<String> = [
        "ios-listening-activity",
        "ios-nowplaying-contentlayers-impl",
        "ios-feature-nowplaying",
        "ios-feature-canvas",
        "ios-feature-cover-art-snake",
        "ios-feature-readalong",
        "ios-creativeworkcommons-cover-art-tilt-configuration-kit",
    ]

    private static let liveConfigurationAssignmentKeys: Set<String> = [
        "ios-campfire-properties-impl.campfire_feature_enabled",
        "ios-feature-sidedrawer-platform.is_list_page_enabled",
    ]

    static func shouldPreserveLiveConfigurationAssignment(scope: String, name: String) -> Bool {
        liveConfigurationAssignmentScopes.contains(scope)
            || liveConfigurationAssignmentKeys.contains("\(scope).\(name)")
    }

    static func shouldOverwriteResolvedConfiguration(requested: Bool) -> Bool {
        requested
    }
}

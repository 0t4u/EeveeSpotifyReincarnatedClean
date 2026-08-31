import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError("FAIL: \(message)")
    }
}

let protectedAttributes = ServerSidedFeaturePolicy.serverAuthoritativeAccountAttributes
for name in [
    "offline",
    "audio-quality",
    "social-session",
    "social-session-free-tier",
    "jam-social-session",
] {
    require(protectedAttributes.contains(name), "missing server-authoritative attribute: \(name)")
}

require(
    ServerSidedFeaturePolicy.shouldOverwriteResolvedConfiguration(
        requested: true
    ),
    "explicit overwrite must use the version-selected bundled configuration"
)
require(
    !ServerSidedFeaturePolicy.shouldOverwriteResolvedConfiguration(
        requested: false
    ),
    "disabled overwrite must retain the live configuration"
)

for scope in [
    "ios-listening-activity",
    "ios-nowplaying-contentlayers-impl",
    "ios-feature-nowplaying",
    "ios-feature-canvas",
    "ios-feature-cover-art-snake",
    "ios-feature-readalong",
    "ios-creativeworkcommons-cover-art-tilt-configuration-kit",
] {
    require(
        ServerSidedFeaturePolicy.shouldPreserveLiveConfigurationAssignment(
            scope: scope,
            name: "any_flag"
        ),
        "live UI assignment scope must be preserved: \(scope)"
    )
}

require(
    !ServerSidedFeaturePolicy.shouldPreserveLiveConfigurationAssignment(
        scope: "ios-feature-search",
        name: "any_flag"
    ),
    "unrelated scopes must continue using the bundled configuration"
)

require(
    ServerSidedFeaturePolicy.premiumGatedJamEntryPoint == .init(
        scope: "ios-sociallistening-configuration-impl",
        name: "premium_gated_start_jam_buttons_enabled"
    ),
    "Premium-gated Jam entry point changed unexpectedly"
)

print("Server-sided feature policy tests passed")

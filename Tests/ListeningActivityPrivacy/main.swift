import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError("FAIL: \(message)") }
}

require(
    ListeningActivityPrivacyPolicy.isListeningActivityKey("publishListeningActivity"),
    "new Listening Activity setting key must be recognized"
)
require(
    ListeningActivityPrivacyPolicy.isListeningActivityKey("publish-activity"),
    "legacy Listening Activity setting key must be recognized"
)
require(
    ListeningActivityPrivacyPolicy.isListeningActivityKey("settings.publish-activity"),
    "scoped native setting key must be recognized"
)
require(
    !ListeningActivityPrivacyPolicy.isListeningActivityKey("viewListeningActivity"),
    "viewing other users must remain a separate setting"
)

require(
    ListeningActivityPrivacyPolicy.shouldForceOff(latchedOff: true, storedValue: true),
    "latched OFF must win over a later stored ON"
)
require(
    !ListeningActivityPrivacyPolicy.shouldRejectWrite(
        latchedOff: false,
        storedValue: true,
        requestedValue: true
    ),
    "ON must keep normal Spotify behavior"
)
require(
    ListeningActivityPrivacyPolicy.shouldRejectWrite(
        latchedOff: true,
        storedValue: false,
        requestedValue: true
    ),
    "a latched OFF must reject re-enabling"
)
require(
    !ListeningActivityPrivacyPolicy.shouldRejectWrite(
        latchedOff: false,
        storedValue: true,
        requestedValue: false
    ),
    "turning OFF must remain writable"
)

print("Listening Activity privacy tests passed")

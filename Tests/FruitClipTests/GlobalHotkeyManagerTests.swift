import Foundation
import Testing

@testable import FruitClip

@Suite("GlobalHotkeyManager Tests")
@MainActor
struct GlobalHotkeyManagerTests {
    private func makeSettings() -> SettingsStore {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return SettingsStore(defaults: defaults)
    }

    @Test("Configured hotkeys include only Board by default")
    func boardOnlyByDefault() {
        let settings = makeSettings()
        let manager = GlobalHotkeyManager(settingsStore: settings) { _ in }

        let registrations = manager.configuredHotkeys()

        #expect(registrations.count == 1)
        #expect(registrations[0].action == .openBoard)
        #expect(registrations[0].shortcut == .openBoardDefault)
    }

    @Test("Configured hotkeys include Star when enabled")
    func starIncludedWhenEnabled() {
        let settings = makeSettings()
        settings.openStarShortcut = ShortcutConfiguration(
            keyCode: 0x03,
            modifiers: 0x0100 | 0x0200
        )
        settings.openStarShortcutEnabled = true

        let manager = GlobalHotkeyManager(settingsStore: settings) { _ in }
        let registrations = manager.configuredHotkeys()

        #expect(registrations.count == 2)
        #expect(registrations.map(\.action).contains(.openBoard))
        #expect(registrations.map(\.action).contains(.openStar))
    }
}

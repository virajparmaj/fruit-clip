import Foundation
import Testing

@testable import FruitClip

@Suite("SettingsStore Tests")
@MainActor
struct SettingsStoreTests {
    private func makeStore() -> SettingsStore {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return SettingsStore(defaults: defaults)
    }

    @Test("Default values are correct")
    func defaultValues() {
        let store = makeStore()
        #expect(store.maxHistoryCount == 50)
        #expect(store.isPaused == false)
        #expect(store.isFirstLaunch == true)
        #expect(store.launchAtLogin == false)
        #expect(store.openBoardShortcut == .openBoardDefault)
        #expect(store.openStarShortcutEnabled == false)
        #expect(store.openStarShortcut == nil)
        #expect(store.starItemShortcut == .starItemDefault)
        #expect(store.deleteItemShortcut == .deleteItemDefault)
        #expect(store.switchToStarShortcut == .switchToStarDefault)
        #expect(store.copySelectedShortcut == .copySelectedDefault)
        #expect(store.focusSearchShortcut == .focusSearchDefault)
        #expect(store.boardRetentionPolicy == .oneWeek)
        #expect(store.starRetentionPolicy == .oneMonth)
        #expect(store.popupFontSize == PopupFontSize.default)
    }

    @Test("maxHistoryCount clamps to minimum of 1")
    func maxHistoryCountClampsToMin() {
        let store = makeStore()
        store.maxHistoryCount = 0
        #expect(store.maxHistoryCount == 1)
        store.maxHistoryCount = -5
        #expect(store.maxHistoryCount == 1)
    }

    @Test("maxHistoryCount clamps to maximum of 100")
    func maxHistoryCountClampsToMax() {
        let store = makeStore()
        store.maxHistoryCount = 999
        #expect(store.maxHistoryCount == 100)
    }

    @Test("popupFontSize clamps between 11 and 15")
    func popupFontSizeClamps() {
        let store = makeStore()
        store.popupFontSize = 99
        #expect(store.popupFontSize == PopupFontSize.max)

        store.popupFontSize = 1
        #expect(store.popupFontSize == PopupFontSize.min)
    }

    @Test("Open Board shortcut persists through re-creation")
    func openBoardShortcutPersistence() {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults)
        store1.openBoardShortcut = ShortcutConfiguration(
            keyCode: 0x0C,
            modifiers: 0x0800
        )

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.openBoardShortcut.keyCode == 0x0C)
        #expect(store2.openBoardShortcut.modifiers == 0x0800)
    }

    @Test("Popup shortcuts and star settings persist")
    func popupShortcutPersistence() {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults)
        store1.openStarShortcutEnabled = true
        store1.openStarShortcut = ShortcutConfiguration(
            keyCode: 0x03,
            modifiers: 0x0100 | 0x0200
        )
        store1.starItemShortcut = ShortcutConfiguration(keyCode: 0x00, modifiers: 0)
        store1.boardRetentionPolicy = .oneDay
        store1.starRetentionPolicy = .threeMonths
        store1.popupFontSize = 15

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.openStarShortcutEnabled == true)
        #expect(store2.openStarShortcut == store1.openStarShortcut)
        #expect(store2.starItemShortcut == ShortcutConfiguration(keyCode: 0x00, modifiers: 0))
        #expect(store2.boardRetentionPolicy == .oneDay)
        #expect(store2.starRetentionPolicy == .threeMonths)
        #expect(store2.popupFontSize == 15)
    }

    @Test("Legacy favorites keys do not migrate into star settings")
    func legacyFavoritesKeysDoNotMigrate() throws {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        defaults.set(true, forKey: "openFavoritesShortcutEnabled")
        defaults.set(
            try JSONEncoder().encode(ShortcutConfiguration(keyCode: 0x03, modifiers: 0x0300)),
            forKey: "openFavoritesShortcut"
        )
        defaults.set(
            try JSONEncoder().encode(ShortcutConfiguration(keyCode: 0x01, modifiers: 0)),
            forKey: "favoriteItemShortcut"
        )
        defaults.set(RetentionPolicy.threeMonths.rawValue, forKey: "favoritesRetentionPolicy")

        let store = SettingsStore(defaults: defaults)
        #expect(store.openStarShortcutEnabled == false)
        #expect(store.openStarShortcut == nil)
        #expect(store.starItemShortcut == .starItemDefault)
        #expect(store.starRetentionPolicy == .oneMonth)
    }

    @Test("Legacy hotkey keys migrate into Open Board shortcut")
    func legacyHotkeyMigration() {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(UInt32(0x0D), forKey: "hotkeyKeyCode")
        defaults.set(UInt32(0x1000), forKey: "hotkeyModifiers")

        let store = SettingsStore(defaults: defaults)
        #expect(store.openBoardShortcut.keyCode == 0x0D)
        #expect(store.openBoardShortcut.modifiers == 0x1000)
    }

    @Test("isFirstLaunch persists after set to false")
    func isFirstLaunchPersistence() {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults)
        #expect(store1.isFirstLaunch == true)
        store1.isFirstLaunch = false

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.isFirstLaunch == false)
    }
}

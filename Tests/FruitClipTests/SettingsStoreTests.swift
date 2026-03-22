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
        #expect(store.hotkeyKeyCode == 0x09)
        #expect(store.hotkeyModifiers == 0x0100 | 0x0200)
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

    @Test("Hotkey persists through re-creation")
    func hotkeyPersistence() {
        let suiteName = "com.veer.FruitClip.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let store1 = SettingsStore(defaults: defaults)
        store1.hotkeyKeyCode = 0x0C  // Q key
        store1.hotkeyModifiers = 0x0800  // controlKey

        let store2 = SettingsStore(defaults: defaults)
        #expect(store2.hotkeyKeyCode == 0x0C)
        #expect(store2.hotkeyModifiers == 0x0800)
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

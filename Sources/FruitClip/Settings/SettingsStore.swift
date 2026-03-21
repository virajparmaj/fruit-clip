import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let launchAtLogin = "launchAtLogin"
        static let isPaused = "isPaused"
        static let isFirstLaunch = "isFirstLaunch"
        static let maxHistoryCount = "maxHistoryCount"
    }

    // Default: Cmd+Shift+V — keyCode 0x09 (V), modifiers cmdKey|shiftKey
    @Published var hotkeyKeyCode: UInt32 {
        didSet { defaults.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode) }
    }

    @Published var hotkeyModifiers: UInt32 {
        didSet { defaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers) }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var isPaused: Bool {
        didSet { defaults.set(isPaused, forKey: Keys.isPaused) }
    }

    @Published var isFirstLaunch: Bool {
        didSet { defaults.set(isFirstLaunch, forKey: Keys.isFirstLaunch) }
    }

    @Published var maxHistoryCount: Int {
        didSet { defaults.set(maxHistoryCount, forKey: Keys.maxHistoryCount) }
    }

    init() {
        let registered: [String: Any] = [
            Keys.hotkeyKeyCode: UInt32(0x09),
            Keys.hotkeyModifiers: UInt32(0x0100 | 0x0200),  // cmdKey | shiftKey
            Keys.launchAtLogin: false,
            Keys.isPaused: false,
            Keys.isFirstLaunch: true,
            Keys.maxHistoryCount: 10,
        ]
        defaults.register(defaults: registered)

        self.hotkeyKeyCode = UInt32(defaults.integer(forKey: Keys.hotkeyKeyCode))
        self.hotkeyModifiers = UInt32(defaults.integer(forKey: Keys.hotkeyModifiers))
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.isPaused = defaults.bool(forKey: Keys.isPaused)
        self.isFirstLaunch = defaults.bool(forKey: Keys.isFirstLaunch)
        self.maxHistoryCount = defaults.integer(forKey: Keys.maxHistoryCount)
    }
}

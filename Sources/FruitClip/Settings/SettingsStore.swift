import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults

    private enum Keys {
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let launchAtLogin = "launchAtLogin"
        static let isPaused = "isPaused"
        static let isFirstLaunch = "isFirstLaunch"
        static let maxHistoryCount = "maxHistoryCount"
        static let dismissOnMouseMove = "dismissOnMouseMove"
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
        didSet {
            let clamped = max(1, min(maxHistoryCount, 100))
            if clamped != maxHistoryCount { maxHistoryCount = clamped; return }
            defaults.set(maxHistoryCount, forKey: Keys.maxHistoryCount)
        }
    }

    @Published var dismissOnMouseMove: Bool {
        didSet { defaults.set(dismissOnMouseMove, forKey: Keys.dismissOnMouseMove) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let registered: [String: Any] = [
            Keys.hotkeyKeyCode: UInt32(0x09),
            Keys.hotkeyModifiers: UInt32(0x0100 | 0x0200),  // cmdKey | shiftKey
            Keys.launchAtLogin: false,
            Keys.isPaused: false,
            Keys.isFirstLaunch: true,
            Keys.maxHistoryCount: 50,
            Keys.dismissOnMouseMove: false,
        ]
        defaults.register(defaults: registered)

        self.hotkeyKeyCode = UInt32(defaults.integer(forKey: Keys.hotkeyKeyCode))
        self.hotkeyModifiers = UInt32(defaults.integer(forKey: Keys.hotkeyModifiers))
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.isPaused = defaults.bool(forKey: Keys.isPaused)
        self.isFirstLaunch = defaults.bool(forKey: Keys.isFirstLaunch)
        self.maxHistoryCount = defaults.integer(forKey: Keys.maxHistoryCount)
        self.dismissOnMouseMove = defaults.bool(forKey: Keys.dismissOnMouseMove)
    }
}

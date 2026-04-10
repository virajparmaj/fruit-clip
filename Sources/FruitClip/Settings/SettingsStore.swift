import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults

    private enum Keys {
        static let openBoardShortcut = "openBoardShortcut"
        static let openStarShortcut = "openStarShortcut"
        static let openStarShortcutEnabled = "openStarShortcutEnabled"
        static let starItemShortcut = "starItemShortcut"
        static let deleteItemShortcut = "deleteItemShortcut"
        static let switchToStarShortcut = "switchToStarShortcut"
        static let copySelectedShortcut = "copySelectedShortcut"
        static let focusSearchShortcut = "focusSearchShortcut"
        static let launchAtLogin = "launchAtLogin"
        static let isPaused = "isPaused"
        static let isFirstLaunch = "isFirstLaunch"
        static let maxHistoryCount = "maxHistoryCount"
        static let popupFontSize = "popupFontSize"
        static let dismissOnMouseMove = "dismissOnMouseMove"
        static let boardRetentionPolicy = "boardRetentionPolicy"
        static let starRetentionPolicy = "starRetentionPolicy"

        static let legacyHotkeyKeyCode = "hotkeyKeyCode"
        static let legacyHotkeyModifiers = "hotkeyModifiers"
    }

    @Published var openBoardShortcut: ShortcutConfiguration {
        didSet { saveShortcut(openBoardShortcut, forKey: Keys.openBoardShortcut) }
    }

    @Published var openStarShortcut: ShortcutConfiguration? {
        didSet { saveOptionalShortcut(openStarShortcut, forKey: Keys.openStarShortcut) }
    }

    @Published var openStarShortcutEnabled: Bool {
        didSet { defaults.set(openStarShortcutEnabled, forKey: Keys.openStarShortcutEnabled) }
    }

    @Published var starItemShortcut: ShortcutConfiguration {
        didSet { saveShortcut(starItemShortcut, forKey: Keys.starItemShortcut) }
    }

    @Published var deleteItemShortcut: ShortcutConfiguration {
        didSet { saveShortcut(deleteItemShortcut, forKey: Keys.deleteItemShortcut) }
    }

    @Published var switchToStarShortcut: ShortcutConfiguration {
        didSet { saveShortcut(switchToStarShortcut, forKey: Keys.switchToStarShortcut) }
    }

    @Published var copySelectedShortcut: ShortcutConfiguration {
        didSet { saveShortcut(copySelectedShortcut, forKey: Keys.copySelectedShortcut) }
    }

    @Published var focusSearchShortcut: ShortcutConfiguration {
        didSet { saveShortcut(focusSearchShortcut, forKey: Keys.focusSearchShortcut) }
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

    @Published var popupFontSize: Int {
        didSet {
            let clamped = max(PopupFontSize.min, min(popupFontSize, PopupFontSize.max))
            if clamped != popupFontSize { popupFontSize = clamped; return }
            defaults.set(popupFontSize, forKey: Keys.popupFontSize)
        }
    }

    @Published var dismissOnMouseMove: Bool {
        didSet { defaults.set(dismissOnMouseMove, forKey: Keys.dismissOnMouseMove) }
    }

    @Published var boardRetentionPolicy: RetentionPolicy {
        didSet { defaults.set(boardRetentionPolicy.rawValue, forKey: Keys.boardRetentionPolicy) }
    }

    @Published var starRetentionPolicy: RetentionPolicy {
        didSet { defaults.set(starRetentionPolicy.rawValue, forKey: Keys.starRetentionPolicy) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let registered: [String: Any] = [
            Keys.launchAtLogin: false,
            Keys.isPaused: false,
            Keys.isFirstLaunch: true,
            Keys.maxHistoryCount: 50,
            Keys.popupFontSize: PopupFontSize.default,
            Keys.dismissOnMouseMove: false,
            Keys.openStarShortcutEnabled: false,
            Keys.boardRetentionPolicy: RetentionPolicy.oneWeek.rawValue,
            Keys.starRetentionPolicy: RetentionPolicy.oneMonth.rawValue,
        ]
        defaults.register(defaults: registered)

        self.openBoardShortcut = Self.loadOpenBoardShortcut(from: defaults)
        self.openStarShortcut = Self.loadShortcut(
            from: defaults,
            key: Keys.openStarShortcut
        )
        self.openStarShortcutEnabled = defaults.bool(forKey: Keys.openStarShortcutEnabled)
        self.starItemShortcut = Self.loadShortcut(
            from: defaults,
            key: Keys.starItemShortcut,
            fallback: .starItemDefault
        )
        self.deleteItemShortcut = Self.loadShortcut(
            from: defaults,
            key: Keys.deleteItemShortcut,
            fallback: .deleteItemDefault
        )
        self.switchToStarShortcut = Self.loadShortcut(
            from: defaults,
            key: Keys.switchToStarShortcut,
            fallback: .switchToStarDefault
        )
        self.copySelectedShortcut = Self.loadShortcut(
            from: defaults,
            key: Keys.copySelectedShortcut,
            fallback: .copySelectedDefault
        )
        self.focusSearchShortcut = Self.loadShortcut(
            from: defaults,
            key: Keys.focusSearchShortcut,
            fallback: .focusSearchDefault
        )
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.isPaused = defaults.bool(forKey: Keys.isPaused)
        self.isFirstLaunch = defaults.bool(forKey: Keys.isFirstLaunch)
        self.maxHistoryCount = defaults.integer(forKey: Keys.maxHistoryCount)
        self.popupFontSize = defaults.integer(forKey: Keys.popupFontSize)
        self.dismissOnMouseMove = defaults.bool(forKey: Keys.dismissOnMouseMove)
        self.boardRetentionPolicy = RetentionPolicy(
            rawValue: defaults.string(forKey: Keys.boardRetentionPolicy) ?? ""
        ) ?? .oneWeek
        self.starRetentionPolicy = RetentionPolicy(
            rawValue: defaults.string(forKey: Keys.starRetentionPolicy) ?? ""
        ) ?? .oneMonth
    }

    var activeOpenStarShortcut: ShortcutConfiguration? {
        guard openStarShortcutEnabled else { return nil }
        return openStarShortcut
    }

    private func saveShortcut(_ shortcut: ShortcutConfiguration, forKey key: String) {
        guard let data = try? JSONEncoder().encode(shortcut) else { return }
        defaults.set(data, forKey: key)
    }

    private func saveOptionalShortcut(_ shortcut: ShortcutConfiguration?, forKey key: String) {
        guard let shortcut else {
            defaults.removeObject(forKey: key)
            return
        }
        saveShortcut(shortcut, forKey: key)
    }

    private static func loadOpenBoardShortcut(from defaults: UserDefaults) -> ShortcutConfiguration {
        if let stored = loadShortcut(from: defaults, key: Keys.openBoardShortcut) {
            return stored
        }

        if defaults.object(forKey: Keys.legacyHotkeyKeyCode) != nil,
           defaults.object(forKey: Keys.legacyHotkeyModifiers) != nil {
            return ShortcutConfiguration(
                keyCode: UInt32(defaults.integer(forKey: Keys.legacyHotkeyKeyCode)),
                modifiers: UInt32(defaults.integer(forKey: Keys.legacyHotkeyModifiers))
            )
        }

        return .openBoardDefault
    }

    private static func loadShortcut(
        from defaults: UserDefaults,
        key: String,
        fallback: ShortcutConfiguration
    ) -> ShortcutConfiguration {
        loadShortcut(from: defaults, key: key) ?? fallback
    }

    private static func loadShortcut(
        from defaults: UserDefaults,
        key: String
    ) -> ShortcutConfiguration? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ShortcutConfiguration.self, from: data)
    }
}

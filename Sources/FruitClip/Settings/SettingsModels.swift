import Carbon
import Foundation

struct ShortcutConfiguration: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let openBoardDefault = ShortcutConfiguration(
        keyCode: 0x09,
        modifiers: UInt32(cmdKey | shiftKey)
    )

    static let starItemDefault = ShortcutConfiguration(keyCode: 0x01, modifiers: 0)  // S
    static let deleteItemDefault = ShortcutConfiguration(keyCode: 0x02, modifiers: 0)  // D
    static let switchToStarDefault = ShortcutConfiguration(keyCode: 0x03, modifiers: 0)  // F
    static let copySelectedDefault = ShortcutConfiguration(
        keyCode: 0x08,
        modifiers: UInt32(cmdKey)
    )
    static let focusSearchDefault = ShortcutConfiguration(
        keyCode: 0x03,
        modifiers: UInt32(cmdKey)
    )
}

enum PopupFontSize {
    static let min = 11
    static let `default` = 12
    static let max = 15
}

enum RetentionPolicy: String, CaseIterable, Codable, Identifiable, Sendable {
    case oneDay
    case oneWeek
    case oneMonth
    case threeMonths
    case never

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneDay: "1 day"
        case .oneWeek: "1 week"
        case .oneMonth: "1 month"
        case .threeMonths: "3 months"
        case .never: "Never"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .oneDay: 24 * 60 * 60
        case .oneWeek: 7 * 24 * 60 * 60
        case .oneMonth: 30 * 24 * 60 * 60
        case .threeMonths: 90 * 24 * 60 * 60
        case .never: nil
        }
    }
}

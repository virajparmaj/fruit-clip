import Foundation

enum PopupInputMode: Equatable {
    case search
    case list
}

enum PopupKeyboardCommand: Equatable {
    case moveUp
    case moveDown
    case confirmSelection
    case escape
    case deleteKey
    case digit(Int)
    case toggleStar
    case deleteSelected
    case switchToStar
    case copySelected
    case focusSearch
}

enum PopupKeyboardEffect: Equatable {
    case clearSearch
    case dismiss
    case pasteSelection
    case toggleStar
    case deleteSelection
    case copySelection
}

struct PopupKeyboardState: Equatable {
    var inputMode: PopupInputMode
    var activeTab: PopupTab
    var selectedIndex: Int?
    var visibleItemCount: Int
    var hasSearchText: Bool

    var normalizedSelectedIndex: Int? {
        guard visibleItemCount > 0 else { return nil }
        guard let selectedIndex else { return 0 }
        return min(max(selectedIndex, 0), visibleItemCount - 1)
    }
}

struct PopupKeyboardOutcome: Equatable {
    var state: PopupKeyboardState
    var effect: PopupKeyboardEffect?
    var navigationSource: PopupNavigationSource?
    var handled: Bool
}

enum PopupKeyboardRouter {
    static func route(
        _ command: PopupKeyboardCommand,
        state: PopupKeyboardState
    ) -> PopupKeyboardOutcome {
        switch command {
        case .moveDown:
            return moveSelection(direction: 1, state: state)
        case .moveUp:
            return moveSelection(direction: -1, state: state)
        case .confirmSelection:
            guard state.normalizedSelectedIndex != nil else {
                return PopupKeyboardOutcome(state: state, effect: nil, navigationSource: nil, handled: false)
            }
            return PopupKeyboardOutcome(
                state: state,
                effect: .pasteSelection,
                navigationSource: nil,
                handled: true
            )
        case .escape:
            if state.hasSearchText {
                var nextState = state
                nextState.inputMode = .search
                return PopupKeyboardOutcome(
                    state: nextState,
                    effect: .clearSearch,
                    navigationSource: nil,
                    handled: true
                )
            }

            return PopupKeyboardOutcome(
                state: state,
                effect: .dismiss,
                navigationSource: nil,
                handled: true
            )
        case .deleteKey, .deleteSelected:
            guard state.inputMode == .list, state.normalizedSelectedIndex != nil else {
                return PopupKeyboardOutcome(state: state, effect: nil, navigationSource: nil, handled: false)
            }
            return PopupKeyboardOutcome(
                state: state,
                effect: .deleteSelection,
                navigationSource: nil,
                handled: true
            )
        case .digit(let digit):
            guard state.inputMode == .list, (1...state.visibleItemCount).contains(digit) else {
                return PopupKeyboardOutcome(state: state, effect: nil, navigationSource: nil, handled: false)
            }

            var nextState = state
            nextState.selectedIndex = digit - 1

            return PopupKeyboardOutcome(
                state: nextState,
                effect: .pasteSelection,
                navigationSource: nil,
                handled: true
            )
        case .toggleStar:
            guard state.inputMode == .list, state.normalizedSelectedIndex != nil else {
                return PopupKeyboardOutcome(state: state, effect: nil, navigationSource: nil, handled: false)
            }
            return PopupKeyboardOutcome(
                state: state,
                effect: .toggleStar,
                navigationSource: nil,
                handled: true
            )
        case .switchToStar:
            guard state.inputMode == .list, state.activeTab == .board else {
                return PopupKeyboardOutcome(state: state, effect: nil, navigationSource: nil, handled: false)
            }

            var nextState = state
            nextState.activeTab = .star
            nextState.inputMode = .search
            nextState.selectedIndex = nil

            return PopupKeyboardOutcome(
                state: nextState,
                effect: nil,
                navigationSource: nil,
                handled: true
            )
        case .copySelected:
            guard state.inputMode == .list, state.normalizedSelectedIndex != nil else {
                return PopupKeyboardOutcome(state: state, effect: nil, navigationSource: nil, handled: false)
            }

            return PopupKeyboardOutcome(
                state: state,
                effect: .copySelection,
                navigationSource: nil,
                handled: true
            )
        case .focusSearch:
            var nextState = state
            nextState.inputMode = .search
            return PopupKeyboardOutcome(
                state: nextState,
                effect: nil,
                navigationSource: nil,
                handled: true
            )
        }
    }

    private static func moveSelection(
        direction: Int,
        state: PopupKeyboardState
    ) -> PopupKeyboardOutcome {
        guard state.visibleItemCount > 0 else {
            return PopupKeyboardOutcome(state: state, effect: nil, navigationSource: nil, handled: false)
        }

        var nextState = state

        if state.inputMode == .search {
            nextState.inputMode = .list
            nextState.selectedIndex = direction > 0 ? 0 : state.visibleItemCount - 1
            return PopupKeyboardOutcome(
                state: nextState,
                effect: nil,
                navigationSource: direction > 0 ? .enterFromSearchDown : .enterFromSearchUp,
                handled: true
            )
        }

        let currentIndex = state.normalizedSelectedIndex ?? (direction > 0 ? -1 : state.visibleItemCount)
        let nextIndex = min(
            max(currentIndex + direction, 0),
            state.visibleItemCount - 1
        )
        nextState.selectedIndex = nextIndex

        return PopupKeyboardOutcome(
            state: nextState,
            effect: nil,
            navigationSource: direction > 0 ? .moveDown : .moveUp,
            handled: true
        )
    }
}

import SwiftUI

enum PopupNavigationSource: Equatable {
    case enterFromSearchUp
    case enterFromSearchDown
    case moveUp
    case moveDown
}

struct PopupScrollRequest: Equatable {
    var targetIndex: Int
    var anchor: UnitPoint?
}

enum PopupScrollPlanner {
    static func plan(
        previousIndex: Int?,
        nextIndex: Int?,
        visibleItemCount: Int,
        source: PopupNavigationSource
    ) -> PopupScrollRequest? {
        guard visibleItemCount > 0, let nextIndex else { return nil }

        switch source {
        case .enterFromSearchDown:
            return PopupScrollRequest(targetIndex: nextIndex, anchor: .top)
        case .enterFromSearchUp:
            return PopupScrollRequest(targetIndex: nextIndex, anchor: .bottom)
        case .moveDown:
            guard previousIndex != nextIndex, nextIndex < visibleItemCount - 1 else { return nil }
            return PopupScrollRequest(targetIndex: nextIndex + 1, anchor: .bottom)
        case .moveUp:
            guard previousIndex != nextIndex, nextIndex > 0 else { return nil }
            return PopupScrollRequest(targetIndex: nextIndex - 1, anchor: nil)
        }
    }
}

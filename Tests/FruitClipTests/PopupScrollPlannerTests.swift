import SwiftUI
import Testing

@testable import FruitClip

@Suite("PopupScrollPlanner Tests")
struct PopupScrollPlannerTests {
    @Test("Down from search reveals first item near top")
    func enterFromSearchDown() {
        let request = PopupScrollPlanner.plan(
            previousIndex: nil,
            nextIndex: 0,
            visibleItemCount: 8,
            source: .enterFromSearchDown
        )

        #expect(request == PopupScrollRequest(targetIndex: 0, anchor: .top))
    }

    @Test("Up from search reveals last item near bottom")
    func enterFromSearchUp() {
        let request = PopupScrollPlanner.plan(
            previousIndex: nil,
            nextIndex: 7,
            visibleItemCount: 8,
            source: .enterFromSearchUp
        )

        #expect(request == PopupScrollRequest(targetIndex: 7, anchor: .bottom))
    }

    @Test("Repeated down movement uses one-row lookahead")
    func repeatedDownMovement() {
        let request = PopupScrollPlanner.plan(
            previousIndex: 3,
            nextIndex: 4,
            visibleItemCount: 8,
            source: .moveDown
        )

        #expect(request == PopupScrollRequest(targetIndex: 5, anchor: .bottom))
    }

    @Test("Repeated up movement uses previous-row reveal")
    func repeatedUpMovement() {
        let request = PopupScrollPlanner.plan(
            previousIndex: 4,
            nextIndex: 3,
            visibleItemCount: 8,
            source: .moveUp
        )

        #expect(request == PopupScrollRequest(targetIndex: 2, anchor: nil))
    }

    @Test("No request is emitted at top and bottom boundaries")
    func noRequestAtBoundaries() {
        let topRequest = PopupScrollPlanner.plan(
            previousIndex: 0,
            nextIndex: 0,
            visibleItemCount: 8,
            source: .moveUp
        )
        #expect(topRequest == nil)

        let bottomRequest = PopupScrollPlanner.plan(
            previousIndex: 7,
            nextIndex: 7,
            visibleItemCount: 8,
            source: .moveDown
        )
        #expect(bottomRequest == nil)
    }
}

import Testing

@testable import FruitClip

@Suite("PopupKeyboardRouter Tests")
struct PopupKeyboardRouterTests {
    @Test("Up and Down enter list mode from search")
    func entersListModeFromSearch() {
        let baseState = PopupKeyboardState(
            inputMode: .search,
            activeTab: .board,
            selectedIndex: nil,
            visibleItemCount: 4,
            hasSearchText: false
        )

        let downOutcome = PopupKeyboardRouter.route(.moveDown, state: baseState)
        #expect(downOutcome.handled == true)
        #expect(downOutcome.state.inputMode == .list)
        #expect(downOutcome.state.selectedIndex == 0)
        #expect(downOutcome.navigationSource == .enterFromSearchDown)

        let upOutcome = PopupKeyboardRouter.route(.moveUp, state: baseState)
        #expect(upOutcome.handled == true)
        #expect(upOutcome.state.inputMode == .list)
        #expect(upOutcome.state.selectedIndex == 3)
        #expect(upOutcome.navigationSource == .enterFromSearchUp)
    }

    @Test("Repeated navigation stays within visible bounds")
    func repeatedNavigationClampsSelection() {
        let state = PopupKeyboardState(
            inputMode: .list,
            activeTab: .board,
            selectedIndex: 1,
            visibleItemCount: 3,
            hasSearchText: false
        )

        let movedDown = PopupKeyboardRouter.route(.moveDown, state: state)
        #expect(movedDown.state.selectedIndex == 2)
        #expect(movedDown.navigationSource == .moveDown)

        let clampedDown = PopupKeyboardRouter.route(.moveDown, state: movedDown.state)
        #expect(clampedDown.state.selectedIndex == 2)
        #expect(clampedDown.navigationSource == .moveDown)

        let movedUp = PopupKeyboardRouter.route(.moveUp, state: clampedDown.state)
        #expect(movedUp.state.selectedIndex == 1)
        #expect(movedUp.navigationSource == .moveUp)
    }

    @Test("S, D, and F only trigger from list mode")
    func shortcutsRequireListMode() {
        let searchState = PopupKeyboardState(
            inputMode: .search,
            activeTab: .board,
            selectedIndex: 0,
            visibleItemCount: 2,
            hasSearchText: false
        )

        #expect(PopupKeyboardRouter.route(.toggleStar, state: searchState).handled == false)
        #expect(PopupKeyboardRouter.route(.deleteSelected, state: searchState).handled == false)
        #expect(PopupKeyboardRouter.route(.switchToStar, state: searchState).handled == false)

        let listState = PopupKeyboardState(
            inputMode: .list,
            activeTab: .board,
            selectedIndex: 0,
            visibleItemCount: 2,
            hasSearchText: false
        )

        #expect(PopupKeyboardRouter.route(.toggleStar, state: listState).effect == .toggleStar)
        #expect(PopupKeyboardRouter.route(.deleteSelected, state: listState).effect == .deleteSelection)

        let starOutcome = PopupKeyboardRouter.route(.switchToStar, state: listState)
        #expect(starOutcome.handled == true)
        #expect(starOutcome.state.activeTab == .star)
        #expect(starOutcome.state.inputMode == .search)
    }

    @Test("Digits jump to visible items in list mode")
    func digitsJumpToVisibleItems() {
        let listState = PopupKeyboardState(
            inputMode: .list,
            activeTab: .board,
            selectedIndex: 0,
            visibleItemCount: 5,
            hasSearchText: false
        )

        let outcome = PopupKeyboardRouter.route(.digit(4), state: listState)
        #expect(outcome.handled == true)
        #expect(outcome.state.selectedIndex == 3)
        #expect(outcome.effect == .pasteSelection)

        let searchState = PopupKeyboardState(
            inputMode: .search,
            activeTab: .board,
            selectedIndex: 0,
            visibleItemCount: 5,
            hasSearchText: false
        )
        #expect(PopupKeyboardRouter.route(.digit(4), state: searchState).handled == false)
    }

    @Test("Escape clears search before dismissing")
    func escapeClearsSearchFirst() {
        let searchState = PopupKeyboardState(
            inputMode: .list,
            activeTab: .board,
            selectedIndex: 0,
            visibleItemCount: 3,
            hasSearchText: true
        )

        let clearOutcome = PopupKeyboardRouter.route(.escape, state: searchState)
        #expect(clearOutcome.handled == true)
        #expect(clearOutcome.effect == .clearSearch)
        #expect(clearOutcome.state.inputMode == .search)

        let dismissState = PopupKeyboardState(
            inputMode: .search,
            activeTab: .board,
            selectedIndex: 0,
            visibleItemCount: 3,
            hasSearchText: false
        )

        let dismissOutcome = PopupKeyboardRouter.route(.escape, state: dismissState)
        #expect(dismissOutcome.handled == true)
        #expect(dismissOutcome.effect == .dismiss)
    }
}

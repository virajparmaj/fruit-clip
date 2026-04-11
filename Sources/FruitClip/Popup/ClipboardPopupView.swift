import AppKit
import SwiftUI

private let fruitClipBlue = Color(red: 0.2, green: 0.5, blue: 1.0)
private let fruitClipGold = Color(red: 0.97, green: 0.8, blue: 0.24)
private let fruitClipDelete = Color(red: 0.92, green: 0.32, blue: 0.36)
private let popupRowHeight: CGFloat = 72
private let popupRowCornerRadius: CGFloat = 13
private let popupThumbnailSize: CGFloat = 44
private let popupRowTrailingInset: CGFloat = 50

struct ClipboardPopupView: View {
    @ObservedObject var historyStore: ClipboardHistoryStore
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var presentationState: PopupPresentationState

    let onSelect: (ClipboardHistoryItem) -> Void
    let onCopy: (ClipboardHistoryItem) -> Void
    let onDelete: (ClipboardHistoryItem) -> Void
    let onToggleStar: (ClipboardHistoryItem) -> Void
    let onDismiss: () -> Void

    @State private var selectedItemID: UUID?
    @State private var searchText: String = ""
    @State private var pendingScrollRequest: PopupScrollRequest?
    @State private var deletingItemIDs: Set<UUID> = []
    @FocusState private var isSearchFocused: Bool

    private var activeTab: PopupTab { presentationState.activeTab }

    private var filteredItems: [ClipboardHistoryItem] {
        let baseItems = historyStore.items.filter {
            activeTab == .board || $0.isStarred
        }

        guard !searchText.isEmpty else { return baseItems }

        let query = searchText.lowercased()
        return baseItems.filter { $0.preview.lowercased().contains(query) }
    }

    private var selectedItem: ClipboardHistoryItem? {
        guard let selectedItemID else { return nil }
        return filteredItems.first(where: { $0.id == selectedItemID }) ?? filteredItems.first
    }

    private var selectedIndex: Int? {
        guard let selectedItem else { return nil }
        return filteredItems.firstIndex(where: { $0.id == selectedItem.id })
    }

    private var popupKeyboardState: PopupKeyboardState {
        PopupKeyboardState(
            inputMode: presentationState.inputMode,
            activeTab: activeTab,
            selectedIndex: selectedIndex,
            visibleItemCount: filteredItems.count,
            hasSearchText: !searchText.isEmpty
        )
    }

    private var visibleIDs: [UUID] { filteredItems.map(\.id) }
    private var popupTextSize: CGFloat { CGFloat(settingsStore.popupFontSize) }
    private var popupCaptionSize: CGFloat { max(popupTextSize - 2, 9) }
    private var popupChipLabelSize: CGFloat { max(popupTextSize - 1, 10) }
    private var popupTitleSize: CGFloat { popupTextSize + 4 }
    private var popupTabFontSize: CGFloat { max(popupTextSize - 1, 11) }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            Divider().opacity(0.14)

            if filteredItems.isEmpty {
                emptyState
            } else {
                itemList
            }

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.black.opacity(0.55))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(AnimatedGradientBorder(cornerRadius: 18))
        .background(PopupKeyMonitor(onKeyDown: handlePopupKeyEvent))
        .padding(8)
        .onAppear {
            handleActivationReset()
        }
        .onChange(of: presentationState.activationID) { _, _ in
            handleActivationReset()
        }
        .onChange(of: presentationState.inputMode) { _, newMode in
            switch newMode {
            case .search:
                focusSearchField()
            case .list:
                isSearchFocused = false
            }
        }
        .onChange(of: isSearchFocused) { _, isFocused in
            if isFocused && presentationState.inputMode != .search {
                presentationState.inputMode = .search
            }
        }
        .onChange(of: searchText) { _, _ in
            stabilizeSelection()
        }
        .onChange(of: visibleIDs) { _, _ in
            stabilizeSelection()
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            PopupTabPicker(activeTab: Binding(
                get: { presentationState.activeTab },
                set: { newTab in
                    presentationState.selectTab(newTab)
                    stabilizeSelection()
                }
            ), fontSize: popupTabFontSize)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(activeTab.searchPlaceholder, text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: popupTextSize))
                .focused($isSearchFocused)
                .accessibilityLabel(activeTab == .board ? "Filter board items" : "Filter starred items")
                .onTapGesture {
                    presentationState.inputMode = .search
                }

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: activeTab == .board ? "rectangle.stack" : "star")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)

            Text(emptyTitle)
                .font(.system(size: popupTitleSize, weight: .semibold))
                .foregroundStyle(.primary)

            Text(emptySubtitle)
                .font(.system(size: popupChipLabelSize))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 230)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(emptyTitle)
    }

    private var itemList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(filteredItems) { item in
                        ClipboardItemRow(
                            item: item,
                            isSelected: item.id == selectedItem?.id,
                            isDeleting: deletingItemIDs.contains(item.id),
                            textSize: popupTextSize,
                            onSelect: { onSelect(item) },
                            onToggleStar: { performStarToggle(item) },
                            onDelete: { performDelete(item) }
                        )
                        .id(item.id)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .trailing))
                            )
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .onChange(of: selectedItem?.id) { _, newValue in
                guard let request = pendingScrollRequest,
                      filteredItems.indices.contains(request.targetIndex) else { return }

                let targetID = filteredItems[request.targetIndex].id
                withAnimation(.easeOut(duration: 0.18)) {
                    proxy.scrollTo(targetID, anchor: request.anchor)
                }
                pendingScrollRequest = nil
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.14)

            HStack(spacing: 8) {
                ShortcutRecapChip(
                    key: HotkeyFormatter.format(settingsStore.starItemShortcut),
                    label: activeTab == .star ? "Unstar" : "Star",
                    keyFontSize: popupCaptionSize,
                    labelFontSize: popupChipLabelSize
                )
                ShortcutRecapChip(
                    key: HotkeyFormatter.format(settingsStore.deleteItemShortcut),
                    label: "Delete",
                    keyFontSize: popupCaptionSize,
                    labelFontSize: popupChipLabelSize
                )
                ShortcutRecapChip(
                    key: HotkeyFormatter.format(settingsStore.focusSearchShortcut),
                    label: "Search",
                    keyFontSize: popupCaptionSize,
                    labelFontSize: popupChipLabelSize
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }

    private var emptyTitle: String {
        switch activeTab {
        case .board:
            searchText.isEmpty ? "Board is empty" : "No matches"
        case .star:
            searchText.isEmpty ? "No starred items yet" : "No starred matches"
        }
    }

    private var emptySubtitle: String {
        switch activeTab {
        case .board:
            searchText.isEmpty
                ? "Copy something and it will appear here instantly."
                : "Try a different search or clear the current filter."
        case .star:
            searchText.isEmpty
                ? "Star an item in Board to keep it close at hand."
                : "Try a different search or switch back to Board."
        }
    }

    private func handleActivationReset() {
        searchText = ""
        selectedItemID = nil
        pendingScrollRequest = nil
        presentationState.inputMode = .search
        deletingItemIDs.removeAll()
        focusSearchField()
    }

    private func stabilizeSelection() {
        if filteredItems.isEmpty {
            selectedItemID = nil
            return
        }

        guard let selectedItemID else { return }

        if filteredItems.contains(where: { $0.id == selectedItemID }) {
            return
        }

        self.selectedItemID = filteredItems.first?.id
    }

    private func performStarToggle(_ item: ClipboardHistoryItem) {
        withAnimation(.easeInOut(duration: 0.18)) {
            onToggleStar(item)
        }
    }

    private func performDelete(_ item: ClipboardHistoryItem) {
        let nextSelection = replacementSelection(afterDeleting: item)
        deletingItemIDs.insert(item.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedItemID = nextSelection
                onDelete(item)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            deletingItemIDs.remove(item.id)
        }
    }

    private func replacementSelection(afterDeleting item: ClipboardHistoryItem) -> UUID? {
        guard let currentIndex = filteredItems.firstIndex(where: { $0.id == item.id }) else {
            return filteredItems.first?.id
        }

        if currentIndex + 1 < filteredItems.count {
            return filteredItems[currentIndex + 1].id
        }

        if currentIndex > 0 {
            return filteredItems[currentIndex - 1].id
        }

        return nil
    }

    private func handlePopupKeyEvent(_ event: NSEvent) -> Bool {
        guard let command = command(for: event) else { return false }

        let outcome = PopupKeyboardRouter.route(command, state: popupKeyboardState)
        guard outcome.handled else { return false }

        apply(outcome)
        return true
    }

    private func command(for event: NSEvent) -> PopupKeyboardCommand? {
        switch event.keyCode {
        case 0x24, 0x4C:
            return .confirmSelection
        case 0x33:
            return .deleteKey
        case 0x35:
            return .escape
        case 0x7D:
            return .moveDown
        case 0x7E:
            return .moveUp
        default:
            break
        }

        if matches(event, shortcut: settingsStore.focusSearchShortcut) {
            return .focusSearch
        }

        if matches(event, shortcut: settingsStore.starItemShortcut) {
            return .toggleStar
        }

        if matches(event, shortcut: settingsStore.deleteItemShortcut) {
            return .deleteSelected
        }

        if matches(event, shortcut: settingsStore.switchToStarShortcut) {
            return .switchToStar
        }

        if matches(event, shortcut: settingsStore.copySelectedShortcut) {
            return .copySelected
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.isEmpty,
           let characters = event.charactersIgnoringModifiers,
           let digit = Int(characters),
           (1...9).contains(digit) {
            return .digit(digit)
        }

        return nil
    }

    private func apply(_ outcome: PopupKeyboardOutcome) {
        let previousIndex = selectedIndex

        if outcome.state.activeTab != presentationState.activeTab {
            presentationState.selectTab(outcome.state.activeTab)
        } else {
            presentationState.inputMode = outcome.state.inputMode
        }

        if let selectionIndex = outcome.state.selectedIndex,
           filteredItems.indices.contains(selectionIndex) {
            selectedItemID = filteredItems[selectionIndex].id
        } else if outcome.state.selectedIndex == nil {
            selectedItemID = nil
        }

        pendingScrollRequest = outcome.navigationSource.flatMap { source in
            PopupScrollPlanner.plan(
                previousIndex: previousIndex,
                nextIndex: outcome.state.selectedIndex,
                visibleItemCount: filteredItems.count,
                source: source
            )
        }

        switch outcome.effect {
        case .clearSearch:
            searchText = ""
        case .dismiss:
            onDismiss()
        case .pasteSelection:
            guard let item = item(at: outcome.state.selectedIndex) else { return }
            onSelect(item)
        case .toggleStar:
            guard let item = item(at: outcome.state.selectedIndex) else { return }
            performStarToggle(item)
        case .deleteSelection:
            guard let item = item(at: outcome.state.selectedIndex) else { return }
            performDelete(item)
        case .copySelection:
            guard let item = item(at: outcome.state.selectedIndex) else { return }
            onCopy(item)
        case nil:
            break
        }
    }

    private func item(at index: Int?) -> ClipboardHistoryItem? {
        if let index, filteredItems.indices.contains(index) {
            return filteredItems[index]
        }

        return selectedItem
    }

    private func focusSearchField() {
        DispatchQueue.main.async {
            isSearchFocused = true
        }
    }

    private func matches(_ event: NSEvent, shortcut: ShortcutConfiguration) -> Bool {
        guard UInt32(event.keyCode) == shortcut.keyCode else { return false }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return HotkeyFormatter.cocoaToCarbonModifiers(modifiers.rawValue) == shortcut.modifiers
    }
}

private struct PopupKeyMonitor: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool

    func makeNSView(context: Context) -> PopupKeyMonitorView {
        let view = PopupKeyMonitorView()
        view.onKeyDown = onKeyDown
        return view
    }

    func updateNSView(_ nsView: PopupKeyMonitorView, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
}

private final class PopupKeyMonitorView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        startMonitoring()
    }

    override func removeFromSuperview() {
        stopMonitoring()
        super.removeFromSuperview()
    }

    private func startMonitoring() {
        guard monitor == nil else { return }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard event.window === self.window else { return event }
            return self.onKeyDown?(event) == true ? nil : event
        }
    }

    private func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

private struct PopupTabPicker: View {
    @Binding var activeTab: PopupTab
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PopupTab.allCases) { tab in
                Button(action: { activeTab = tab }) {
                    Text(tab.title)
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundStyle(activeTab == tab ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(activeTab == tab ? fruitClipBlue.opacity(0.94) : Color.clear)
                        .shadow(
                            color: activeTab == tab ? fruitClipBlue.opacity(0.25) : .clear,
                            radius: 6
                        )
                )
            }
        }
        .padding(4)
        .frame(width: 176)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.24))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
        )
    }
}

private struct ShortcutRecapChip: View {
    let key: String
    let label: String
    let keyFontSize: CGFloat
    let labelFontSize: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            Text(key)
                .font(.system(size: keyFontSize, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.white.opacity(0.08))
                )

            Text(label)
                .font(.system(size: labelFontSize, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardHistoryItem
    let isSelected: Bool
    let isDeleting: Bool
    let textSize: CGFloat
    let onSelect: () -> Void
    let onToggleStar: () -> Void
    let onDelete: () -> Void

    @State private var cachedThumbnail: NSImage? = nil
    @State private var isHovering = false

    private var storageDir: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("com.veer.FruitClip", isDirectory: true)
    }

    var body: some View {
        HStack(spacing: 10) {
            starButton

            if item.kind == .image {
                VStack(alignment: .leading, spacing: 4) {
                    thumbnailView
                        .frame(maxWidth: .infinity, maxHeight: 160)
                    Text(item.preview)
                        .font(.system(size: textSize - 1, weight: .regular))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(item.preview)
                    .font(.system(size: textSize, weight: .regular))
                    .lineLimit(2, reservesSpace: true)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, popupRowTrailingInset)
        .padding(.vertical, 10)
        .frame(minHeight: popupRowHeight)
        .background(rowBackground)
        .overlay(
            RoundedRectangle(cornerRadius: popupRowCornerRadius)
                .stroke(Color.white.opacity(isSelected ? 0.09 : 0.04), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            elapsedBadge
                .padding(.top, 8)
                .padding(.trailing, 8)
        }
        .overlay(alignment: .bottomTrailing) {
            deleteButton
                .padding(.trailing, 8)
                .padding(.bottom, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: popupRowCornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: popupRowCornerRadius))
        .onHover { isHovering = $0 }
        .accessibilityLabel(
            "\(item.kind == .text ? "Text" : "Image") item: \(item.preview), \(elapsedString(from: item.timestamp))\(item.isStarred ? ", starred" : "")"
        )
        .accessibilityHint("Press Return to paste, S to star, D to delete")
        .task(id: item.payloadFilename) {
            guard item.kind == .image else { return }
            cachedThumbnail = await ThumbnailCache.shared.loadThumbnailAsync(
                for: item.payloadFilename,
                storageDir: storageDir
            )
        }
        .onTapGesture(perform: onSelect)
    }

    private var starButton: some View {
        Button(action: onToggleStar) {
            Image(systemName: item.isStarred ? "star.fill" : "star")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(item.isStarred ? fruitClipGold : starInactiveColor)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }

    private var elapsedBadge: some View {
        Text(elapsedString(from: item.timestamp))
            .font(.system(size: max(textSize - 2, 9), weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(elapsedBadgeForegroundColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(elapsedBadgeBackground)
            )
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(deleteButtonColor)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .opacity((isHovering || isSelected || isDeleting) ? 1 : 0.42)
    }

    private var starInactiveColor: Color {
        isSelected ? .white.opacity(0.55) : .secondary.opacity(0.85)
    }

    private var elapsedBadgeForegroundColor: Color {
        if isDeleting {
            return .white.opacity(0.96)
        }

        if isSelected {
            return .white.opacity(0.9)
        }

        return .secondary.opacity(isHovering ? 0.96 : 0.9)
    }

    private var elapsedBadgeBackground: Color {
        if isDeleting {
            return .white.opacity(0.2)
        }

        if isSelected {
            return .white.opacity(0.16)
        }

        return Color.white.opacity(isHovering ? 0.12 : 0.08)
    }

    private var deleteButtonColor: Color {
        if isDeleting { return .white }
        if isSelected { return .white.opacity(0.88) }
        return fruitClipDelete.opacity(isHovering ? 0.96 : 0.75)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: popupRowCornerRadius)
            .fill(backgroundFill)
            .shadow(color: shadowColor, radius: isSelected ? 10 : 0)
    }

    private var backgroundFill: Color {
        if isDeleting {
            return fruitClipDelete.opacity(0.85)
        }

        if isSelected {
            return fruitClipBlue.opacity(0.95)
        }

        return Color.white.opacity(isHovering ? 0.07 : 0.03)
    }

    private var shadowColor: Color {
        if isDeleting {
            return fruitClipDelete.opacity(0.28)
        }

        if isSelected {
            return fruitClipBlue.opacity(0.35)
        }

        return .clear
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail = cachedThumbnail {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? .white.opacity(0.78) : .secondary)
                }
        }
    }
}

func elapsedString(from date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))
    let minutes = seconds / 60
    if minutes < 1 { return "<1m" }
    if minutes < 60 { return "\(minutes)m" }
    let hours = minutes / 60
    if hours < 24 { return "\(hours)h" }
    let days = hours / 24
    return "\(days)d"
}

struct AnimatedGradientBorder: View {
    let cornerRadius: CGFloat
    @State private var rotationAngle: Double = 0

    var body: some View {
        let gradient = AngularGradient(
            stops: [
                .init(color: Color(red: 0.1, green: 0.35, blue: 0.9), location: 0.0),
                .init(color: Color(red: 0.4, green: 0.7, blue: 1.0), location: 0.25),
                .init(color: Color(red: 0.15, green: 0.45, blue: 0.95), location: 0.5),
                .init(color: Color(red: 0.3, green: 0.6, blue: 1.0), location: 0.75),
                .init(color: Color(red: 0.1, green: 0.35, blue: 0.9), location: 1.0),
            ],
            center: .center,
            angle: .degrees(rotationAngle)
        )

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(lineWidth: 3)
                .fill(gradient)
                .blur(radius: 6)
                .opacity(0.7)

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(lineWidth: 1.5)
                .fill(gradient)
        }
        .onAppear {
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
        .allowsHitTesting(false)
    }
}

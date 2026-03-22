import AppKit
import SwiftUI

private let fruitClipBlue = Color(red: 0.2, green: 0.5, blue: 1.0)

struct ClipboardPopupView: View {
    let items: [ClipboardHistoryItem]
    let onSelect: (ClipboardHistoryItem) -> Void
    let onCopy: (ClipboardHistoryItem) -> Void
    let onDelete: (ClipboardHistoryItem) -> Void
    let onTogglePin: (ClipboardHistoryItem) -> Void
    let onDismiss: () -> Void

    @State private var selectedIndex: Int = 0
    @State private var searchText: String = ""
    @State private var scrollAnchor: UnitPoint = .top
    @FocusState private var isSearchFocused: Bool
    @FocusState private var isListFocused: Bool

    private var filteredItems: [ClipboardHistoryItem] {
        if searchText.isEmpty { return items }
        return items.filter { $0.preview.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().opacity(0.3)
            if filteredItems.isEmpty {
                emptyState
            } else {
                itemList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .overlay(AnimatedGradientBorder(cornerRadius: 16))
        .padding(8)
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField("Search clips...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFocused)
                .onKeyPress(.downArrow) {
                    navigate(direction: 1)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    navigate(direction: -1)
                    return .handled
                }
                .onKeyPress(.escape) {
                    if !searchText.isEmpty {
                        searchText = ""
                        return .handled
                    }
                    onDismiss()
                    return .handled
                }
                .onKeyPress(.return) {
                    guard selectedIndex < filteredItems.count else { return .ignored }
                    onSelect(filteredItems[selectedIndex])
                    return .handled
                }
                .accessibilityLabel("Filter clipboard history")
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No clipboard history" : "No matches")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "Copy something to get started" : "Try a different search")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .focusEffectDisabled()
        .focused($isListFocused)
        .onKeyPress(.escape) { onDismiss(); return .handled }
        .accessibilityLabel(searchText.isEmpty ? "No clipboard history" : "No search results")
    }

    private var itemList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(
                            item: item,
                            isSelected: index == selectedIndex,
                            index: index
                        )
                        .id(index)
                        .onTapGesture {
                            onSelect(item)
                        }
                    }
                }
                .padding(8)
            }
            .focusable()
            .focusEffectDisabled()
            .focused($isListFocused)
            .onChange(of: searchText) {
                selectedIndex = 0
                scrollAnchor = .top
            }
            .onChange(of: selectedIndex) { _, new in
                withAnimation(.easeOut(duration: 0.2)) {
                    let scrollIdx = scrollAnchor == .top
                        ? max(0, new - 1)
                        : min(filteredItems.count - 1, new + 1)
                    proxy.scrollTo(scrollIdx, anchor: scrollAnchor)
                }
            }
            .onKeyPress(.upArrow) {
                navigate(direction: -1)
                return .handled
            }
            .onKeyPress(.downArrow) {
                navigate(direction: 1)
                return .handled
            }
            .onKeyPress(.return) {
                guard selectedIndex < filteredItems.count else { return .ignored }
                onSelect(filteredItems[selectedIndex])
                return .handled
            }
            .onKeyPress(.escape) {
                onDismiss()
                return .handled
            }
            .onKeyPress(.delete) {
                guard selectedIndex < filteredItems.count else { return .ignored }
                let item = filteredItems[selectedIndex]
                onDelete(item)
                if selectedIndex >= filteredItems.count - 1 {
                    selectedIndex = max(0, filteredItems.count - 2)
                }
                return .handled
            }
            .onKeyPress(characters: .init(charactersIn: "p")) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                guard selectedIndex < filteredItems.count else { return .ignored }
                onTogglePin(filteredItems[selectedIndex])
                return .handled
            }
            .onKeyPress(characters: .init(charactersIn: "c")) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                guard selectedIndex < filteredItems.count else { return .ignored }
                onCopy(filteredItems[selectedIndex])
                return .handled
            }
            .onKeyPress(characters: .init(charactersIn: "f")) { press in
                guard press.modifiers.contains(.command) else { return .ignored }
                isListFocused = false
                isSearchFocused = true
                return .handled
            }
            .onKeyPress(characters: .init(charactersIn: "123456789")) { press in
                guard let digit = Int(String(press.characters)), digit >= 1, digit <= 9 else {
                    return .ignored
                }
                let index = digit - 1
                guard index < filteredItems.count else { return .ignored }
                onSelect(filteredItems[index])
                return .handled
            }
        }
    }

    private func navigate(direction: Int) {
        let newIndex = selectedIndex + direction
        guard newIndex >= 0, newIndex < filteredItems.count else { return }
        scrollAnchor = direction > 0 ? .bottom : .top
        selectedIndex = newIndex
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardHistoryItem
    let isSelected: Bool
    let index: Int

    var body: some View {
        HStack(spacing: 10) {
            // Number badge for quick access (1-9)
            if index < 9 {
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.6) : Color.secondary.opacity(0.5))
                    .frame(width: 14)
            }

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white : fruitClipBlue)
            }

            if item.kind == .image {
                itemIcon
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(elapsedString(from: item.timestamp))
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? fruitClipBlue : Color.clear)
                .shadow(color: isSelected ? fruitClipBlue.opacity(0.4) : .clear, radius: 4)
        )
        .contentShape(Rectangle())
        .accessibilityLabel("\(item.kind == .text ? "Text" : "Image") item: \(item.preview), \(elapsedString(from: item.timestamp))\(item.isPinned ? ", pinned" : "")")
        .accessibilityHint("Press Return to paste, Delete to remove, Command P to pin")
    }

    @ViewBuilder
    private var itemIcon: some View {
        let storageDir = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!.appendingPathComponent("com.veer.FruitClip", isDirectory: true)

        if let image = ThumbnailCache.shared.thumbnail(for: item.payloadFilename, storageDir: storageDir) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Image(systemName: "photo")
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? .white : .secondary)
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
                .init(color: Color(red: 0.1, green: 0.35, blue: 0.9),  location: 0.0),
                .init(color: Color(red: 0.4, green: 0.7,  blue: 1.0),  location: 0.25),
                .init(color: Color(red: 0.15, green: 0.45, blue: 0.95), location: 0.5),
                .init(color: Color(red: 0.3, green: 0.6,  blue: 1.0),  location: 0.75),
                .init(color: Color(red: 0.1, green: 0.35, blue: 0.9),  location: 1.0),
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

import AppKit
import SwiftUI

struct ClipboardPopupView: View {
    let items: [ClipboardHistoryItem]
    let onSelect: (ClipboardHistoryItem) -> Void
    let onDismiss: () -> Void

    @State private var selectedIndex: Int = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                itemList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            isFocused = true
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clipboard")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No clipboard history")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Copy something to get started")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .focused($isFocused)
        .onKeyPress(.escape) { onDismiss(); return .handled }
    }

    private var itemList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(
                            item: item,
                            isSelected: index == selectedIndex
                        )
                        .id(index)
                        .onTapGesture {
                            onSelect(item)
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
            }
            .focusable()
            .focused($isFocused)
            .onKeyPress(.upArrow) {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                    proxy.scrollTo(selectedIndex, anchor: .center)
                }
                return .handled
            }
            .onKeyPress(.downArrow) {
                if selectedIndex < items.count - 1 {
                    selectedIndex += 1
                    proxy.scrollTo(selectedIndex, anchor: .center)
                }
                return .handled
            }
            .onKeyPress(.return) {
                guard selectedIndex < items.count else { return .ignored }
                onSelect(items[selectedIndex])
                return .handled
            }
            .onKeyPress(.escape) {
                onDismiss()
                return .handled
            }
        }
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardHistoryItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            itemIcon
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundStyle(isSelected ? .white : .primary)

                Text(item.timestamp, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var itemIcon: some View {
        switch item.kind {
        case .text:
            Image(systemName: "doc.text")
                .font(.system(size: 16))
                .foregroundStyle(isSelected ? .white : .secondary)
        case .image:
            if let data = loadThumbnailData() {
                Image(nsImage: NSImage(data: data) ?? NSImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
        }
    }

    private func loadThumbnailData() -> Data? {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let storageDir = appSupport.appendingPathComponent(
            "com.veer.FruitClip", isDirectory: true)
        let fileURL = storageDir.appendingPathComponent(item.payloadFilename)
        return try? Data(contentsOf: fileURL)
    }
}

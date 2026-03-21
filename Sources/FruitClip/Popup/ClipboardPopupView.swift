import AppKit
import SwiftUI

private let fruitClipBlue = Color(red: 0.2, green: 0.5, blue: 1.0)

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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .overlay(AnimatedGradientBorder(cornerRadius: 16))
        .padding(8)
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
        .focusEffectDisabled()
        .focused($isFocused)
        .onKeyPress(.escape) { onDismiss(); return .handled }
    }

    private var itemList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
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
            .focusEffectDisabled()
            .focused($isFocused)
            .onKeyPress(.upArrow) {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(selectedIndex, anchor: .center)
                    }
                }
                return .handled
            }
            .onKeyPress(.downArrow) {
                if selectedIndex < items.count - 1 {
                    selectedIndex += 1
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(selectedIndex, anchor: .center)
                    }
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
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? fruitClipBlue : Color.clear)
                .shadow(color: isSelected ? fruitClipBlue.opacity(0.4) : .clear, radius: 4)
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
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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
            // Soft outer glow
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(lineWidth: 3)
                .fill(gradient)
                .blur(radius: 6)
                .opacity(0.7)

            // Crisp border line
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

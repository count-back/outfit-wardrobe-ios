import SwiftUI

struct OutfitHistoryRow: View {
    let outfit: Outfit
    let reuseAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(outfit.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(HistoryPalette.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "cloud.sun")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(outfit.snapshots.count) 件单品")
                    }
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(HistoryPalette.textSecondary)
                    .lineLimit(1)
                }

                Spacer(minLength: 12)

                scoreBubble
            }

            thumbnailGrid

            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.forward")
                        .font(.system(size: 10, weight: .bold))
                    Text("View Details")
                }
                .font(.caption2.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(HistoryPalette.secondary)

                Spacer()

                Button {
                    reuseAction()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text("Re-use")
                    }
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(HistoryPalette.onPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(HistoryPalette.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(HistoryPalette.surfaceLowest)
            .shadow(color: HistoryPalette.textPrimary.opacity(0.06), radius: 14, x: 0, y: 8)
    }

    private var scoreBubble: some View {
        VStack(spacing: 2) {
            Text("\(outfit.finalScore)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(HistoryPalette.primaryDim)

            Text("SCORE")
                .font(.caption2.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(HistoryPalette.primaryDim.opacity(0.8))
        }
        .frame(width: 42, height: 42)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(HistoryPalette.primaryContainer)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var thumbnailGrid: some View {
        let slots = thumbnailSlots

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                thumbnailCell(for: slot)
            }
        }
    }

    private func thumbnailCell(for slot: ThumbnailSlot) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HistoryPalette.surfaceLow)

            switch slot {
            case let .item(item):
                if let image = item.thumbnailData?.swiftUIImage ?? item.imageData.swiftUIImage {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder(for: item.category.rawValue)
                }

            case let .more(count):
                VStack(spacing: 4) {
                    Text("+\(count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(HistoryPalette.textPrimary)
                    Text("MORE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(HistoryPalette.textSecondary)
                }
            case .empty:
                placeholder(for: "item")
            }
        }
        .frame(height: 74)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func placeholder(for label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HistoryPalette.outline)
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(HistoryPalette.outline)
        }
    }

    private var thumbnailSlots: [ThumbnailSlot] {
        let visibleItems = Array(outfit.items.prefix(3))
        let remainingCount = max(outfit.items.count - visibleItems.count, 0)

        var slots: [ThumbnailSlot] = visibleItems.map { .item($0) }

        if remainingCount > 0 {
            slots.append(.more(remainingCount))
        }

        while slots.count < 4 {
            slots.append(.empty)
        }

        return slots
    }

    private enum ThumbnailSlot {
        case item(ClothingItem)
        case more(Int)
        case empty
    }
}

private enum HistoryPalette {
    static let background = Color(red: 0.988, green: 0.976, blue: 0.955)
    static let surfaceLowest = Color.white
    static let surfaceLow = Color(red: 0.988, green: 0.976, blue: 0.953)
    static let surfaceHigh = Color(red: 0.941, green: 0.933, blue: 0.902)
    static let primary = Color(red: 0.353, green: 0.412, blue: 0.322)
    static let primaryDim = Color(red: 0.306, green: 0.361, blue: 0.278)
    static let primaryContainer = Color(red: 0.847, green: 0.906, blue: 0.796)
    static let secondary = Color(red: 0.506, green: 0.353, blue: 0.357)
    static let tertiary = Color(red: 0.431, green: 0.388, blue: 0.325)
    static let textPrimary = Color(red: 0.220, green: 0.220, blue: 0.200)
    static let textSecondary = Color(red: 0.396, green: 0.396, blue: 0.369)
    static let outline = Color(red: 0.506, green: 0.506, blue: 0.478)
    static let onPrimary = Color.white
}

import SwiftUI

struct ClothingCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            imageFrame

            VStack(alignment: .leading, spacing: 5) {
                Text(metaText)
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(AtelierTheme.tertiary)
                    .lineLimit(1)

                Text(item.name)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundStyle(AtelierTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
        .padding(8)
        .background(AtelierTheme.surface, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AtelierTheme.shadow, radius: 18, y: 10)
    }

    private var imageFrame: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AtelierTheme.surfaceHigh.opacity(0.52))
                .frame(height: 182)
                .overlay {
                    if let image = item.thumbnailData?.swiftUIImage ?? item.imageData.swiftUIImage {
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(AtelierTheme.secondary)
                    }
                }

            if let staleDays = staleDays, staleDays >= 30 {
                Text("\(staleDays)天")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .foregroundStyle(.white)
                    .background(AtelierTheme.secondary, in: Capsule())
                    .padding(10)
            }
        }
    }

    private var metaText: String {
        let category = item.category.rawValue.uppercased()
        let detail = item.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? item.color
            : item.location

        return "\(category) • \(detail.uppercased())"
    }

    private var staleDays: Int? {
        guard let lastWornDate = item.lastWornDate else { return nil }
        return lastWornDate.daysSinceNow()
    }
}

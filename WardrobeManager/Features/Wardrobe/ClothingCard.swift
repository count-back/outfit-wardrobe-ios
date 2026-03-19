import SwiftUI

struct ClothingCard: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 180)
                    .overlay {
                        if let image = item.imageData.swiftUIImage {
                            image
                                .resizable()
                                .scaledToFit()
                                .padding(16)
                        } else {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }
                    }

                if let staleDays = staleDays, staleDays >= 30 {
                    Text("\(staleDays)天")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.red, in: Capsule())
                        .foregroundStyle(.white)
                        .padding(10)
                }
            }

            Text(item.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Label(item.location, systemImage: "mappin.and.ellipse")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if !item.tags.isEmpty {
                Text(item.tags.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var staleDays: Int? {
        guard let lastWornDate = item.lastWornDate else { return nil }
        return lastWornDate.daysSinceNow()
    }
}

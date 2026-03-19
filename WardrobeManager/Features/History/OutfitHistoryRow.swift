import SwiftUI

struct OutfitHistoryRow: View {
    let outfit: Outfit

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let image = outfit.previewImageData.swiftUIImage {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(outfit.displayName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    ScoreBadge(label: outfit.resolvedScoreLabel)
                    Text(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(outfit.score)")
                    .font(.title3.weight(.bold))

                Circle()
                    .fill(outfit.resolvedScoreLabel.tint)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
    }
}

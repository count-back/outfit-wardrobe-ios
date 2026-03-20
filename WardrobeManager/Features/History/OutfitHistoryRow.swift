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
                    ScoreBadge(label: outfit.finalScoreLabel)
                    Text(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(outfit.finalScore)")
                    .font(.title3.weight(.bold))

                Text("系统 \(outfit.systemScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

import SwiftUI

struct OutfitHistoryRow: View {
    let outfit: Outfit

    var body: some View {
        HStack(spacing: 14) {
            preview

            VStack(alignment: .leading, spacing: 8) {
                Text(outfit.displayName)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(outfit.snapshots.count) 件单品 · \(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    ScoreBadge(label: outfit.finalScoreLabel)
                    adjustmentBadge
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(outfit.finalScore)")
                    .font(.title3.weight(.bold))

                Text("系统 \(outfit.systemScore)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var preview: some View {
        Group {
            if let image = outfit.previewImageData.swiftUIImage {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var adjustmentBadge: some View {
        Text(adjustmentText)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(adjustmentColor.opacity(0.12))
            .foregroundStyle(adjustmentColor)
            .clipShape(Capsule())
    }

    private var adjustmentText: String {
        let adjustment = outfit.scoreAdjustment
        if adjustment == 0 {
            return "未调整"
        }

        return adjustment > 0 ? "+\(adjustment)" : "\(adjustment)"
    }

    private var adjustmentColor: Color {
        let adjustment = outfit.scoreAdjustment

        if adjustment > 0 {
            return .green
        }

        if adjustment < 0 {
            return .orange
        }

        return .secondary
    }
}

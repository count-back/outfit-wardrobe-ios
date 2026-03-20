import SwiftUI

struct OutfitDetailView: View {
    let outfit: Outfit

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                previewSection
                scoreSection
                itemsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var previewSection: some View {
        SectionCard(title: "搜配预览") {
            if let image = outfit.previewImageData.swiftUIImage {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var scoreSection: some View {
        SectionCard(title: "得分分析") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\(outfit.finalScore)")
                        .font(.system(size: 40, weight: .bold))
                    ScoreBadge(label: outfit.finalScoreLabel)
                    Spacer()
                }

                detailRow(title: "系统默认", value: "\(outfit.systemScore) 分")
                detailRow(title: "最终保存", value: "\(outfit.finalScore) 分")
                detailRow(title: "人工调整", value: scoreAdjustmentText)

                Text(outfit.finalScoreComment)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var itemsSection: some View {
        SectionCard(title: "组成单品") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(outfit.snapshots) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.headline)
                        Text("\(item.category.rawValue) · \(item.color) · \(item.style) · \(item.season.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private var scoreAdjustmentText: String {
        let adjustment = outfit.scoreAdjustment
        if adjustment == 0 {
            return "未调整"
        }

        return adjustment > 0 ? "+\(adjustment) 分" : "\(adjustment) 分"
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

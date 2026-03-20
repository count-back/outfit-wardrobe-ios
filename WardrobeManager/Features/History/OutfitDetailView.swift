import SwiftUI

struct OutfitDetailView: View {
    @Environment(AppContainer.self) private var appContainer
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
            VStack(alignment: .leading, spacing: 14) {
                if let image = outfit.previewImageData.swiftUIImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button("再次使用这套") {
                    appContainer.pendingOutfitReuse = OutfitReuseRequest(
                        itemIDs: outfit.items.map(\.id)
                    )
                    appContainer.selectedTab = .outfit
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var scoreSection: some View {
        SectionCard(title: "得分分析") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("\(outfit.score)")
                        .font(.system(size: 40, weight: .bold))
                    ScoreBadge(label: outfit.resolvedScoreLabel)
                    Spacer()
                }

                Text("这是保存这套搜配时确认下来的最终评分。")
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
}

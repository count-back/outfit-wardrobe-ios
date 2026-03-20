import SwiftUI

struct OutfitDetailView: View {
    @Environment(AppContainer.self) private var appContainer
    let outfit: Outfit

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overviewSection
                scoreSection
                itemsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("记录详情")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overviewSection: some View {
        SectionCard(title: "记录概览") {
            VStack(alignment: .leading, spacing: 14) {
                if let image = outfit.previewImageData.swiftUIImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(outfit.displayName)
                            .font(.title3.weight(.bold))
                            .lineLimit(2)

                        Text(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(outfit.snapshots.count) 件单品")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(outfit.finalScore)")
                            .font(.system(size: 42, weight: .bold))
                        ScoreBadge(label: outfit.finalScoreLabel)
                    }
                }

                if let notes = outfit.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("备注")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button("再次使用这套") {
                    appContainer.pendingOutfitReuse = OutfitReuseRequest(
                        itemIDs: outfit.items.map(\.id),
                        scene: outfit.scene ?? "",
                        notes: outfit.notes ?? ""
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
            VStack(alignment: .leading, spacing: 16) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ScoreMetricCard(title: "系统默认", value: outfit.systemScore, rangeLabel: "自动评分")
                    ScoreMetricCard(title: "最终保存", value: outfit.finalScore, rangeLabel: "保存结果")
                    ScoreMetricCard(title: "人工调整", value: outfit.scoreAdjustment, rangeLabel: "与系统分差")
                }

                if let scene = outfit.scene, !scene.isEmpty {
                    detailRow(title: "使用场景", value: scene)
                }
                detailRow(title: "评分标签", value: outfit.finalScoreLabel.rawValue)
                detailRow(title: "评分变化", value: scoreAdjustmentText)

                Text(outfit.finalScoreComment)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var itemsSection: some View {
        SnapshotListSection(snapshots: outfit.snapshots)
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

private struct SnapshotListSection: View {
    let snapshots: [OutfitItemSnapshot]

    var body: some View {
        SectionCard(title: "组成单品") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(snapshots, id: \.id) { item in
                    SnapshotRow(item: item)
                }
            }
        }
    }
}

private struct SnapshotRow: View {
    let item: OutfitItemSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(item.category.rawValue)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }

            Text("\(item.color) · \(item.style)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(item.season.rawValue)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

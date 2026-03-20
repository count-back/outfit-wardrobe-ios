import SwiftUI
import SwiftData

struct ClothingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer
    let item: ClothingItem
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imageSection
                metadataSection
                actionSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("删除这件衣物？", isPresented: $isShowingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                deleteItem()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复。")
        }
    }

    private var imageSection: some View {
        SectionCard(title: "单品图片") {
            if let image = item.imageData.swiftUIImage {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
            }
        }
    }

    private var metadataSection: some View {
        SectionCard(title: "信息") {
            detailRow(title: "分类", value: item.category.rawValue)
            detailRow(title: "主色", value: item.color)
            detailRow(title: "风格", value: item.style)
            detailRow(title: "季节", value: item.season.rawValue)
            detailRow(title: "位置", value: item.location)
            detailRow(title: "标签", value: item.tags.joined(separator: " · ").nonEmpty ?? "无")
            detailRow(title: "最近穿着", value: item.lastWornDate?.formatted(date: .abbreviated, time: .omitted) ?? "暂无")
            detailRow(title: "累计穿着", value: "\(item.wearCount) 次")
        }
    }

    private var actionSection: some View {
        SectionCard(title: "操作") {
            VStack(spacing: 12) {
                Button("今天穿了") {
                    let previousLastWornDate = item.lastWornDate
                    let previousWearCount = item.wearCount
                    item.lastWornDate = .now
                    item.wearCount += 1

                    do {
                        try modelContext.save()
                    } catch {
                        item.lastWornDate = previousLastWornDate
                        item.wearCount = previousWearCount
                        appContainer.showOperationFeedback(
                            OperationFeedback(message: "穿着记录保存失败，请稍后再试。", style: .error),
                            autoDismissAfter: 3_000_000_000
                        )
                        return
                    }

                    appContainer.showOperationFeedback(
                        OperationFeedback(message: "已记录今天穿了这件单品", style: .success)
                    )
                }
                .buttonStyle(.borderedProminent)

                Button("删除这件衣物", role: .destructive) {
                    isShowingDeleteConfirmation = true
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func deleteItem() {
        modelContext.delete(item)

        do {
            try modelContext.save()
            appContainer.showOperationFeedback(
                OperationFeedback(message: "衣物已删除", style: .success)
            )
            dismiss()
        } catch {
            modelContext.rollback()
            appContainer.showOperationFeedback(
                OperationFeedback(message: "删除失败，请稍后再试。", style: .error),
                autoDismissAfter: 3_000_000_000
            )
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

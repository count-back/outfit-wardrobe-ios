import SwiftUI
import SwiftData

struct OutfitBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var allItems: [ClothingItem]

    @State private var topItem: ClothingItem?
    @State private var bottomItem: ClothingItem?
    @State private var outerwearItem: ClothingItem?
    @State private var shoesItem: ClothingItem?
    @State private var accessoryItem: ClothingItem?
    @State private var pickerCategory: ClothingCategory?
    @State private var generatedPreviewImageData: Data?
    @State private var generatedSystemScore: OutfitScore?
    @State private var editableScore = 0
    @State private var sceneText = ""
    @State private var notesText = ""

    private var selectedItems: [ClothingItem] {
        [topItem, bottomItem, outerwearItem, shoesItem, accessoryItem].compactMap { $0 }
    }

    private var canGeneratePreview: Bool {
        topItem != nil && bottomItem != nil
    }

    private var hasGeneratedPreview: Bool {
        generatedPreviewImageData != nil && generatedSystemScore != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                selectionSection
                sceneSection
                previewSection
                if let generatedSystemScore {
                    scoreSection(score: generatedSystemScore)
                }
                saveSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("搜配")
        .sheet(item: $pickerCategory) { category in
            NavigationStack {
                ClothingSelectorView(
                    title: "选择\(category.rawValue)",
                    items: items(for: category),
                    selectedItem: binding(for: category)
                )
            }
        }
        .onChange(of: selectedItems.map(\.id)) { _, _ in
            generatedPreviewImageData = nil
            generatedSystemScore = nil
            editableScore = 0
        }
        .onAppear {
            applyPendingReuseIfNeeded()
        }
        .onChange(of: appContainer.pendingOutfitReuse) { _, _ in
            applyPendingReuseIfNeeded()
        }
        .onChange(of: allItems.map(\.id)) { _, _ in
            applyPendingReuseIfNeeded()
        }
    }

    private var selectionSection: some View {
        SectionCard(title: "单品选择") {
            VStack(spacing: 12) {
                selectionRow(title: "上衣", item: topItem, category: .top, required: true)
                selectionRow(title: "下装", item: bottomItem, category: .pants, alternateCategories: [.pants, .skirt], required: true)
                selectionRow(title: "外套", item: outerwearItem, category: .outerwear, required: false)
                selectionRow(title: "鞋子", item: shoesItem, category: .shoes, required: false)
                selectionRow(title: "配件", item: accessoryItem, category: .accessory, required: false)
            }
        }
    }

    private var previewSection: some View {
        SectionCard(title: "穿搭预览") {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.94, blue: 0.92), Color(red: 0.90, green: 0.92, blue: 0.97)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 430)

                    if let generatedPreviewImageData, let image = UIImage(data: generatedPreviewImageData) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("上身预览")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Try-on")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.7), in: Capsule())
                            }

                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()

                            Text("选品发生变化后，需要重新生成穿搭预览。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 44))
                                .foregroundStyle(.secondary)
                            Text("先选好上衣和下装，再生成穿搭预览。")
                                .font(.headline)
                            Text("这一步会按人体部位生成上身效果预览，不再使用拼贴画板样式。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 28)
                    }
                }

                Button(hasGeneratedPreview ? "重新生成穿搭预览" : "生成穿搭预览") {
                    generatePreview()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canGeneratePreview)
            }
        }
    }

    private func scoreSection(score: OutfitScore) -> some View {
        SectionCard(title: "评分分析") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(editableScore)")
                        .font(.system(size: 44, weight: .bold))
                    ScoreBadge(label: OutfitScore.summary(for: editableScore).label)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("系统默认")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(score.total) 分")
                            .font(.subheadline.weight(.semibold))
                    }

                    HStack {
                        Text("最终保存")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(editableScore) 分")
                            .font(.subheadline.weight(.semibold))
                    }

                    Slider(
                        value: Binding(
                            get: { Double(editableScore) },
                            set: { editableScore = Int($0.rounded()) }
                        ),
                        in: 0...100,
                        step: 1
                    )

                    HStack {
                        Button(" -5 ") {
                            editableScore = max(0, editableScore - 5)
                        }
                        .buttonStyle(.bordered)

                        Button(" +5 ") {
                            editableScore = min(100, editableScore + 5)
                        }
                        .buttonStyle(.bordered)

                        Spacer()

                        Text("当前保存分数：\(editableScore)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("软件先给系统默认分，你可以按自己的判断调整最终保存分数。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var saveSection: some View {
        SectionCard(title: "保存记录") {
            VStack(alignment: .leading, spacing: 10) {
                Text("保存后会记录预览图、得分和单品快照，方便第二天直接参考。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("保存搜配记录") {
                    saveOutfit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasGeneratedPreview)
            }
        }
    }

    private var sceneSection: some View {
        SectionCard(title: "场景与备注") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("场景，例如：周末约会 / 通勤上班", text: $sceneText)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $notesText)
                            .frame(minHeight: 110)
                            .padding(4)

                        if notesText.isEmpty {
                            Text("例如：需要搭配浅色包包，或者下次试试加外套。")
                                .foregroundStyle(.secondary.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text("场景会作为这套穿搭的标题优先展示，备注只保存不占标题位。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func selectionRow(
        title: String,
        item: ClothingItem?,
        category: ClothingCategory,
        alternateCategories: [ClothingCategory] = [],
        required: Bool
    ) -> some View {
        Button {
            pickerCategory = category == .pants && !alternateCategories.isEmpty ? .pants : category
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title + (required ? " *" : ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(item?.name ?? "点击选择")
                        .font(.headline)
                        .foregroundStyle(item == nil ? .secondary : .primary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(item == nil ? Color.secondary.opacity(0.3) : Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.2, dash: item == nil ? [5] : []))
                    .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
        }
        .buttonStyle(.plain)
    }

    private func items(for category: ClothingCategory) -> [ClothingItem] {
        switch category {
        case .pants:
            return allItems.filter { $0.category == .pants || $0.category == .skirt }
        default:
            return allItems.filter { $0.category == category }
        }
    }

    private func binding(for category: ClothingCategory) -> Binding<ClothingItem?> {
        switch category {
        case .top:
            return $topItem
        case .pants:
            return $bottomItem
        case .outerwear:
            return $outerwearItem
        case .shoes:
            return $shoesItem
        case .accessory:
            return $accessoryItem
        case .skirt:
            return $bottomItem
        }
    }

    private func saveOutfit() {
        guard
            let generatedSystemScore,
            let generatedPreviewImageData
        else {
            return
        }

        let outfit = Outfit(
            scene: trimmedScene,
            notes: trimmedNotes,
            items: selectedItems,
            previewImageData: generatedPreviewImageData,
            systemScore: generatedSystemScore,
            finalScore: editableScore
        )

        modelContext.insert(outfit)

        do {
            try modelContext.save()
            appContainer.showOperationFeedback(
                OperationFeedback(message: "搜配记录已保存", style: .success)
            )
        } catch {
            appContainer.showOperationFeedback(
                OperationFeedback(message: "搜配记录保存失败，请稍后再试。", style: .error),
                autoDismissAfter: 3_000_000_000
            )
        }
    }

    private func generatePreview() {
        guard canGeneratePreview else { return }

        generatedPreviewImageData = appContainer.previewComposer.composePreview(for: selectedItems)
        let score = appContainer.scorer.score(items: selectedItems)
        generatedSystemScore = score
        editableScore = score.total
    }

    private var trimmedScene: String? {
        let value = sceneText.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var trimmedNotes: String? {
        let value = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
    private func applyPendingReuseIfNeeded() {
        guard let request = appContainer.pendingOutfitReuse else { return }

        let requestedItems = request.itemIDs.compactMap { itemID in
            allItems.first(where: { $0.id == itemID })
        }

        guard !requestedItems.isEmpty else { return }

        topItem = requestedItems.first(where: { $0.category == .top })
        bottomItem = requestedItems.first(where: { $0.category == .pants || $0.category == .skirt })
        outerwearItem = requestedItems.first(where: { $0.category == .outerwear })
        shoesItem = requestedItems.first(where: { $0.category == .shoes })
        accessoryItem = requestedItems.first(where: { $0.category == .accessory })
        sceneText = request.scene
        notesText = request.notes
        generatedPreviewImageData = nil
        generatedSystemScore = nil
        editableScore = 0
        appContainer.pendingOutfitReuse = nil
    }
}

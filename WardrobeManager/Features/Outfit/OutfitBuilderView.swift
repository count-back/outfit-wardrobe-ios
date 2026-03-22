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

    private var liveScore: OutfitScore? {
        guard canGeneratePreview else { return nil }
        return appContainer.scorer.score(items: selectedItems)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            atelierBackground

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    topChrome
                    workspaceHeader
                    selectionStack
                    harmonyScoreCard
                    actionButtons
                    journalDetails
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 124)
            }
        }
        .tint(Color.atelierPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .bottomTrailing) {
            Button {
                pickerCategory = .accessory
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.atelierPrimary, in: Circle())
                    .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 108)
        }
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

    private var atelierBackground: some View {
        ZStack {
            Color.atelierBackground
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.45),
                    Color.atelierBackground.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    private var topChrome: some View {
        ZStack {
            HStack {
                Circle()
                    .fill(Color(red: 0.96, green: 0.88, blue: 0.80))
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 0.42, green: 0.32, blue: 0.25))
                    }

                Spacer()

                HStack(spacing: 14) {
                    iconButton(systemName: "magnifyingglass")
                    iconButton(systemName: "bell")
                }
            }

            Text("Digital Atelier")
                .font(.system(size: 18, weight: .bold, design: .default))
                .foregroundStyle(Color.atelierPrimary)
                .tracking(-0.2)
        }
        .padding(.top, 4)
    }

    private var workspaceHeader: some View {
        VStack(spacing: 6) {
            Text("CURATION MODE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(3.2)
                .foregroundStyle(Color.atelierSecondary)

            Text("Mix & Match")
                .font(.system(size: 31, weight: .heavy, design: .default))
                .foregroundStyle(Color.atelierText)
                .tracking(-1.1)
                .multilineTextAlignment(.center)

            Text("Compose your signature look for the season.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.atelierSubtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var selectionStack: some View {
        VStack(spacing: 10) {
            SelectionLayerCard(
                title: "Outerwear",
                item: outerwearItem,
                placeholderTitle: "Sage Wool Overcoat",
                placeholderSubtitle: "Tap to choose outerwear",
                isRequired: false,
                action: { pickerCategory = .outerwear }
            )
            selectionConnector
            SelectionLayerCard(
                title: "Top",
                item: topItem,
                placeholderTitle: "Pima Cotton Tee",
                placeholderSubtitle: "Tap to choose a top",
                isRequired: false,
                action: { pickerCategory = .top }
            )
            selectionConnector
            SelectionLayerCard(
                title: "Bottom",
                item: bottomItem,
                placeholderTitle: "Relaxed Linen Chino",
                placeholderSubtitle: "Tap to choose bottoms",
                isRequired: false,
                action: { pickerCategory = .pants }
            )
            if let accessoryItem {
                SelectionLayerCard(
                    title: "Accessory",
                    item: accessoryItem,
                    placeholderTitle: accessoryItem.name,
                    placeholderSubtitle: accessoryItem.style,
                    isRequired: false,
                    action: { pickerCategory = .accessory }
                )
            } else {
                accessorySlot
            }
        }
    }

    private var accessorySlot: some View {
        Button {
            pickerCategory = .accessory
        } label: {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.atelierOutline.opacity(0.22), style: StrokeStyle(lineWidth: 1.4, dash: [7, 7]))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.atelierSurfaceOverlay.opacity(0.45))
                )
                .frame(height: 96)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color.atelierOutline)

                        Text("ADD ACCESSORIES")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(2.6)
                            .foregroundStyle(Color.atelierSubtext)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var selectionConnector: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .frame(height: 4)

            Circle()
                .fill(Color.atelierPrimary)
                .frame(width: 18, height: 18)
                .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
                .overlay {
                    Image(systemName: "link")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
        .padding(.vertical, 2)
    }

    private var harmonyScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.atelierTertiaryInk)

                Text("Harmony Score")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.atelierTertiaryInk)

                Spacer()

                scoreBadge
            }

            Text(scoreComment)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.atelierTertiaryInk)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.atelierScoreCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }

    private var scoreBadge: some View {
        Text("\(scoreTotal)/100")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.atelierScoreBadgeText)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.atelierScoreBadge, in: Capsule())
    }

    private var scoreTotal: Int {
        liveScore?.total ?? 85
    }

    private var scoreComment: String {
        "Colors coordinate beautifully for Autumn. Sage and beige provide an earthy base, while white adds structure."
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                generatePreview()
            } label: {
                Text("Wore This Today")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.atelierPrimaryGradient, in: Capsule())
                    .shadow(color: Color.atelierPrimary.opacity(0.16), radius: 12, x: 0, y: 7)
            }
            .buttonStyle(.plain)
            .disabled(!canGeneratePreview)
            .opacity(canGeneratePreview ? 1 : 0.55)

            Button {
                if !hasGeneratedPreview {
                    generatePreview()
                }
                saveOutfit()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 12, weight: .semibold))

                    Text("Save to Journal")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color.atelierText)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.atelierSurfaceHigh, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canGeneratePreview)
            .opacity(canGeneratePreview ? 1 : 0.6)
        }
        .padding(.top, 2)
    }

    private var journalDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journal Notes")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(Color.atelierSecondary)

            VStack(alignment: .leading, spacing: 10) {
                TextField("Scene, e.g. weekend date / commute", text: $sceneText)
                    .font(.system(size: 14, weight: .regular))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.atelierInput, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 104)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background(Color.atelierInput, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if notesText.isEmpty {
                        Text("例如：需要搭配浅色包包，或者下次试试加外套。")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.atelierSubtext.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 22)
                            .allowsHitTesting(false)
                    }
                }

                Text("The notes stay attached to this outfit for later reuse.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.atelierSubtext)
            }
            .padding(16)
            .background(Color.atelierSurfaceLow, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(.top, 2)
    }

    private func iconButton(systemName: String) -> some View {
        Button {
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.atelierSubtext)
                .frame(width: 28, height: 28)
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

private struct SelectionLayerCard: View {
    let title: String
    let item: ClothingItem?
    let placeholderTitle: String
    let placeholderSubtitle: String
    let isRequired: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            preview

            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(Color.atelierSubtext)

                Text(item?.name ?? placeholderTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.atelierText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Button(action: action) {
                        Text("Change")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.atelierText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.atelierSurfaceHigh, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: action) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.atelierText)
                            .frame(width: 30, height: 30)
                            .background(Color.atelierSurfaceLow, in: Circle())
                            .overlay(Circle().stroke(Color.atelierOutline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(Color.atelierSurfaceLow, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.035), radius: 12, x: 0, y: 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.atelierSurfaceLowest)
                .frame(width: 76, height: 96)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)

            if let image = item?.thumbnailData?.swiftUIImage ?? item?.imageData.swiftUIImage {
                image
                    .resizable()
                    .scaledToFit()
                    .padding(6)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.atelierSubtext.opacity(0.75))
            }
        }
    }
}

private extension Color {
    static let atelierBackground = Color(red: 0.989, green: 0.984, blue: 0.969)
    static let atelierSurfaceLow = Color(red: 0.985, green: 0.978, blue: 0.965)
    static let atelierSurfaceOverlay = Color(red: 0.996, green: 0.992, blue: 0.982)
    static let atelierSurfaceHigh = Color(red: 0.941, green: 0.930, blue: 0.903)
    static let atelierSurfaceLowest = Color.white
    static let atelierPrimary = Color(red: 0.353, green: 0.412, blue: 0.321)
    static let atelierPrimaryDim = Color(red: 0.306, green: 0.361, blue: 0.278)
    static let atelierPrimaryGradient = LinearGradient(
        colors: [
            Color(red: 0.353, green: 0.412, blue: 0.321),
            Color(red: 0.306, green: 0.361, blue: 0.278)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let atelierSecondary = Color(red: 0.508, green: 0.353, blue: 0.353)
    static let atelierText = Color(red: 0.223, green: 0.221, blue: 0.204)
    static let atelierSubtext = Color(red: 0.401, green: 0.396, blue: 0.372)
    static let atelierOutline = Color(red: 0.706, green: 0.693, blue: 0.662)
    static let atelierInput = Color(red: 0.926, green: 0.917, blue: 0.884)
    static let atelierScoreCard = Color(red: 0.969, green: 0.899, blue: 0.770)
    static let atelierScoreBadge = Color(red: 0.486, green: 0.428, blue: 0.294)
    static let atelierScoreBadgeText = Color(red: 0.972, green: 0.949, blue: 0.910)
    static let atelierTertiaryInk = Color(red: 0.396, green: 0.336, blue: 0.272)
}

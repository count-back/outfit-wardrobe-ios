import SwiftUI
import SwiftData

struct ClothingDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer
    let item: ClothingItem
    @State private var isPresentingEditSheet = false
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                imageSection
                titleSection
                metadataSection
                wearHistorySection
                purchaseSection
                careInstructionsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(AtelierTheme.background.opacity(0.92))
        }
        .atelierPageBackground()
        .alert("删除这件衣物？", isPresented: $isShowingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                deleteItem()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复。")
        }
        .sheet(isPresented: $isPresentingEditSheet) {
            NavigationStack {
                AddClothingView(mode: .edit(item))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AtelierTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AtelierTheme.surfaceLow, in: Circle())
            }
            .buttonStyle(.plain)

            Text("Digital Atelier")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AtelierTheme.primary)

            Spacer()

            Circle()
                .fill(AtelierTheme.secondaryContainer)
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "bookmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AtelierTheme.secondary)
                }
        }
    }

    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(red: 0.93, green: 0.93, blue: 0.93))
                .frame(height: 420)
                .overlay {
                    if let image = item.imageData.swiftUIImage {
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(24)
                    }
                }

            VStack(spacing: 10) {
                CircleButton(symbol: "heart.fill", foreground: AtelierTheme.secondary)
                CircleButton(symbol: "square.and.arrow.up", foreground: AtelierTheme.textPrimary)
            }
            .padding(14)
        }
    }

    private var titleSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(AtelierTheme.textPrimary)
                    .lineLimit(2)

                Text(item.style.nonEmpty ?? item.category.englishLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(AtelierTheme.tertiary)
            }

            Spacer()

            Button("Edit Info") {
                isPresentingEditSheet = true
            }
            .buttonStyle(AtelierSecondaryButtonStyle())
        }
    }

    private var metadataSection: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            detailTile(title: "Category", value: item.category.rawValue)
            detailTile(title: "Color", value: item.color)
            detailTile(title: "Style", value: item.style)
            detailTile(title: "Season", value: item.season.rawValue)
        }
    }

    private var wearHistorySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(AtelierTheme.secondary)
                Text("Wear History")
                    .font(.system(.headline, design: .rounded, weight: .bold))
            }

            HStack(spacing: 18) {
                statColumn(title: "Last worn", value: lastWornText)
                Rectangle()
                    .fill(AtelierTheme.surfaceHighest)
                    .frame(width: 1, height: 36)
                statColumn(title: "Total wears", value: "\(item.wearCount) times")
            }

            Button {
                recordWear()
            } label: {
                Label("I wore this today", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(AtelierPrimaryButtonStyle())
        }
        .atelierCard()
    }

    private var purchaseSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Purchase Price")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(AtelierTheme.tertiary)
                Text(purchasePriceText)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AtelierTheme.tertiary)
            }

            Spacer()

            Button("Add to Outfit") {
                appContainer.selectedTab = .outfit
            }
            .buttonStyle(AtelierSecondaryButtonStyle(background: AtelierTheme.tertiary, foreground: .white))
        }
        .atelierCard(background: AtelierTheme.tertiaryContainer, cornerRadius: 28)
    }

    private var careInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Care Instructions")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(AtelierTheme.tertiary)

            Text(item.careInstructions)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(AtelierTheme.textSecondary)
                .lineSpacing(2)
        }
        .padding(.horizontal, 4)
        .overlay(alignment: .trailing) {
            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.68, green: 0.25, blue: 0.15))
                    .padding(10)
                    .background(AtelierTheme.surfaceLow, in: Circle())
            }
        }
    }

    private func detailTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(AtelierTheme.tertiary)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(AtelierTheme.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .atelierCard(background: AtelierTheme.surfaceLow, cornerRadius: 28, padding: 16)
    }

    private func statColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(AtelierTheme.tertiary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AtelierTheme.textPrimary)
        }
    }

    private var purchasePriceText: String {
        guard let purchasePrice = item.purchasePrice else { return "--" }
        return purchasePrice.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    private var lastWornText: String {
        guard let lastWornDate = item.lastWornDate else { return "Never" }
        let days = lastWornDate.daysSinceNow()
        if days <= 0 {
            return "Today"
        }
        if days == 1 {
            return "1 day ago"
        }
        return "\(days) days ago"
    }

    private func recordWear() {
        let previousLastWornDate = item.lastWornDate
        let previousWearCount = item.wearCount
        item.lastWornDate = .now
        item.wearCount += 1

        do {
            try modelContext.save()
            appContainer.showOperationFeedback(
                OperationFeedback(message: "已记录今天穿了这件单品", style: .success)
            )
        } catch {
            item.lastWornDate = previousLastWornDate
            item.wearCount = previousWearCount
            appContainer.showOperationFeedback(
                OperationFeedback(message: "穿着记录保存失败，请稍后再试。", style: .error),
                autoDismissAfter: 3_000_000_000
            )
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
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension ClothingCategory {
    var englishLabel: String {
        switch self {
        case .top:
            return "PREMIUM TOP"
        case .pants:
            return "TAILORED BOTTOM"
        case .skirt:
            return "TAILORED SKIRT"
        case .outerwear:
            return "EDITORIAL OUTERWEAR"
        case .shoes:
            return "CURATED FOOTWEAR"
        case .accessory:
            return "SIGNATURE ACCESSORY"
        }
    }
}

private extension ClothingItem {
    var careInstructions: String {
        let locationText = location.nonEmpty ?? "keep it in a cool, dry space"
        let tagsText = tags.prefix(2).joined(separator: ", ").nonEmpty ?? "soft handling"
        return "Store in \(locationText). Recommended care: \(tagsText). Avoid long sun exposure to preserve texture and shape."
    }
}

private struct CircleButton: View {
    let symbol: String
    let foreground: Color

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: 42, height: 42)
            .background(.white.opacity(0.94), in: Circle())
            .shadow(color: AtelierTheme.shadow, radius: 10, y: 4)
    }
}

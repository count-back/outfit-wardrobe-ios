import SwiftUI
import SwiftData

struct WardrobeListView: View {
    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var items: [ClothingItem]

    @State private var selectedFilter: ClothingCategory?
    @State private var selectedSeason: Season?
    @State private var sortOption: WardrobeSortOption = .recentlyAdded
    @State private var searchText = ""
    @State private var isPresentingAddSheet = false
    @FocusState private var isSearchFocused: Bool

    private var filteredItems: [ClothingItem] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return items
            .filter { item in
                matchesCategory(item) &&
                matchesSeason(item) &&
                matchesKeyword(item, keyword: keyword)
            }
            .sorted(by: sortOption.comparator)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            background

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    searchField
                    categoryFilters
                    filterRail

                    if filteredItems.isEmpty {
                        emptyState
                            .padding(.top, 42)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 14),
                                GridItem(.flexible(), spacing: 14)
                            ],
                            spacing: 14
                        ) {
                            ForEach(filteredItems) { item in
                                NavigationLink {
                                    ClothingDetailView(item: item)
                                } label: {
                                    ClothingCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 124)
            }

            addButton
                .padding(.trailing, 18)
                .padding(.bottom, 108)
        }
        .background(AtelierTheme.background)
        .sheet(isPresented: $isPresentingAddSheet) {
            NavigationStack {
                AddClothingView()
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [AtelierTheme.background, AtelierTheme.surfaceLow],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            avatar

            Text("Digital Atelier")
                .font(.headline.weight(.bold))
                .foregroundStyle(AtelierTheme.primary)

            Spacer(minLength: 8)

            Button {
                isSearchFocused = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AtelierTheme.tertiary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AtelierTheme.secondary, AtelierTheme.secondary.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "person.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
        }
        .frame(width: 30, height: 30)
        .shadow(color: AtelierTheme.shadow, radius: 6, y: 2)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AtelierTheme.textSecondary)

            TextField("Search your closet...", text: $searchText)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .font(.callout)
                .foregroundStyle(AtelierTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(AtelierTheme.surfaceHigh, in: Capsule())
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }

                ForEach(ClothingCategory.primaryFilterCategories) { category in
                    filterChip(title: category.rawValue, isSelected: selectedFilter == category) {
                        selectedFilter = category
                    }
                }

                filterChip(title: ClothingCategory.shoes.rawValue, isSelected: selectedFilter == .shoes) {
                    selectedFilter = .shoes
                }

                filterChip(title: ClothingCategory.accessory.rawValue, isSelected: selectedFilter == .accessory) {
                    selectedFilter = .accessory
                }
            }
            .padding(.vertical, 2)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var filterRail: some View {
        HStack(spacing: 10) {
            Menu {
                Picker("排序", selection: $sortOption) {
                    ForEach(WardrobeSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                filterRailPill(
                    title: sortOption.shortTitle,
                    systemImage: "arrow.up.arrow.down",
                    isSelected: true
                )
            }

            Menu {
                Picker("季节", selection: Binding(
                    get: { selectedSeason ?? .allSeason },
                    set: { selectedSeason = $0 == .allSeason ? nil : $0 }
                )) {
                    Text("全部季节").tag(Season.allSeason)

                    ForEach(Season.allCases.filter { $0 != .allSeason }) { season in
                        Text(season.rawValue).tag(season)
                    }
                }
            } label: {
                filterRailPill(
                    title: selectedSeason?.rawValue ?? "全部季节",
                    systemImage: "calendar",
                    isSelected: selectedSeason != nil
                )
            }

            Spacer(minLength: 0)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(AtelierTheme.tertiary)
    }

    private func filterRailPill(title: String, systemImage: String, isSelected: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? AtelierTheme.surface : AtelierTheme.surfaceHigh, in: Capsule())
        .overlay(
            Capsule()
                .stroke(AtelierTheme.outline.opacity(isSelected ? 0.0 : 0.18), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(AtelierTheme.surfaceHigh)
                    .frame(width: 150, height: 150)

                Image(systemName: items.isEmpty ? "tray" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(AtelierTheme.secondary)
            }

            VStack(spacing: 6) {
                Text(items.isEmpty ? "还没有衣物" : "没有匹配结果")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AtelierTheme.textPrimary)

                Text(items.isEmpty ? "先添加几件常穿单品，衣柜页和搜配页就能跑起来。" : "试试换个关键词，或者放宽排序和筛选条件。")
                    .font(.callout)
                    .foregroundStyle(AtelierTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 10)
            }
            .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var addButton: some View {
        Button {
            isPresentingAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AtelierTheme.primary, in: Circle())
                .shadow(color: AtelierTheme.shadow, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新增衣物")
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? .white : AtelierTheme.textSecondary)
                .background(chipBackground(isSelected: isSelected), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(AtelierTheme.outline.opacity(isSelected ? 0.0 : 0.12), lineWidth: 1)
                )
                .scaleEffect(isSelected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }

    private func chipBackground(isSelected: Bool) -> AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(LinearGradient(
                colors: [AtelierTheme.primary, AtelierTheme.primaryDim],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            return AnyShapeStyle(AtelierTheme.surfaceHigh)
        }
    }

    private func matchesCategory(_ item: ClothingItem) -> Bool {
        guard let selectedFilter else { return true }
        return item.category == selectedFilter
    }

    private func matchesSeason(_ item: ClothingItem) -> Bool {
        guard let selectedSeason else { return true }
        return item.season == selectedSeason
    }

    private func matchesKeyword(_ item: ClothingItem, keyword: String) -> Bool {
        guard !keyword.isEmpty else { return true }

        let normalizedKeyword = keyword.localizedLowercase
        let searchableFields = [
            item.name,
            item.color,
            item.style,
            item.location
        ] + item.tags

        return searchableFields.contains { field in
            field.localizedLowercase.contains(normalizedKeyword)
        }
    }
}

private enum WardrobeSortOption: String, CaseIterable, Identifiable {
    case recentlyAdded
    case recentlyWorn
    case leastWorn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recentlyAdded:
            return "最近添加"
        case .recentlyWorn:
            return "最近穿过"
        case .leastWorn:
            return "穿着次数少"
        }
    }

    var shortTitle: String {
        switch self {
        case .recentlyAdded:
            return "最近添加"
        case .recentlyWorn:
            return "最近穿过"
        case .leastWorn:
            return "低频优先"
        }
    }

    var comparator: (ClothingItem, ClothingItem) -> Bool {
        switch self {
        case .recentlyAdded:
            return { lhs, rhs in
                lhs.createdAt > rhs.createdAt
            }
        case .recentlyWorn:
            return { lhs, rhs in
                switch (lhs.lastWornDate, rhs.lastWornDate) {
                case let (lhsDate?, rhsDate?):
                    return lhsDate > rhsDate
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.createdAt > rhs.createdAt
                }
            }
        case .leastWorn:
            return { lhs, rhs in
                if lhs.wearCount == rhs.wearCount {
                    return lhs.createdAt > rhs.createdAt
                }
                return lhs.wearCount < rhs.wearCount
            }
        }
    }
}

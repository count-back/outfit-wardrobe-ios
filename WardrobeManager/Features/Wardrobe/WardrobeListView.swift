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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                controlBar
                filters
                seasonFilters

                if filteredItems.isEmpty {
                    EmptyStateView(
                        title: items.isEmpty ? "还没有衣物" : "没有匹配结果",
                        subtitle: items.isEmpty
                            ? "先添加几件常穿单品，衣柜页和搜配页就能跑起来。"
                            : "试试换个关键词，或者放宽排序和筛选条件。",
                        systemImage: items.isEmpty ? "tray" : "line.3.horizontal.decrease.circle"
                    )
                    .padding(.top, 60)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
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
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("衣柜")
        .searchable(text: $searchText, prompt: "搜索名称、颜色、风格、位置或标签")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                appContainer.selectedTab = .outfit
            } label: {
                Image(systemName: "wand.and.stars")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(Color.accentColor, in: Circle())
                    .shadow(radius: 8, y: 4)
            }
            .padding()
        }
        .sheet(isPresented: $isPresentingAddSheet) {
            NavigationStack {
                AddClothingView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("共 \(items.count) 件单品")
                    .font(.largeTitle.weight(.bold))
                Text("记录位置、颜色与风格，后面搜配会直接复用。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            Text("当前 \(filteredItems.count) 件")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Menu {
                Picker("排序", selection: $sortOption) {
                    ForEach(WardrobeSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                Label(sortOption.shortTitle, systemImage: "arrow.up.arrow.down")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground), in: Capsule())
            }
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(title: "全部分类", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }

                ForEach(ClothingCategory.primaryFilterCategories) { category in
                    filterChip(title: category.rawValue, isSelected: selectedFilter == category) {
                        selectedFilter = category
                    }
                }
            }
        }
    }

    private var seasonFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(title: "全部季节", isSelected: selectedSeason == nil) {
                    selectedSeason = nil
                }

                ForEach(Season.allCases) { season in
                    filterChip(title: season.rawValue, isSelected: selectedSeason == season) {
                        selectedSeason = season
                    }
                }
            }
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
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

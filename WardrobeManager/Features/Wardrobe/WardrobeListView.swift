import SwiftUI
import SwiftData

struct WardrobeListView: View {
    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var items: [ClothingItem]

    @State private var selectedFilter: ClothingCategory?
    @State private var isPresentingAddSheet = false

    private var filteredItems: [ClothingItem] {
        guard let selectedFilter else { return items }
        return items.filter { $0.category == selectedFilter }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                filters

                if filteredItems.isEmpty {
                    EmptyStateView(
                        title: "还没有衣物",
                        subtitle: "先添加几件常穿单品，衣柜页和搜配页就能跑起来。",
                        systemImage: "tray"
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

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip(title: "全部", isSelected: selectedFilter == nil) {
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
}

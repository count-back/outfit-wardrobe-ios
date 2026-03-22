import SwiftUI
import SwiftData

struct OutfitHistoryView: View {
    @Environment(AppContainer.self) private var appContainer
    @Query(sort: \Outfit.createdAt, order: .reverse) private var outfits: [Outfit]
    @State private var selectedFilterIndex = 0

    private let filterTitles = [
        "All Entries",
        "Autumn 2023",
        "High Scores",
        "Filters"
    ]

    private var groupedOutfits: [(date: Date, outfits: [Outfit])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: outfits) { calendar.startOfDay(for: $0.createdAt) }

        return groups
            .map { (date: $0.key, outfits: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                topBar
                header
                filterBar

                if outfits.isEmpty {
                    EmptyStateView(
                        title: "还没有搜配记录",
                        subtitle: "去搜配页保存几套方案，明天就能直接复用。",
                        systemImage: "clock.badge.xmark"
                    )
                    .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 26) {
                        ForEach(Array(groupedOutfits.enumerated()), id: \.element.date) { index, group in
                            HistoryTimelineGroup(
                                date: group.date,
                                outfits: group.outfits,
                                isLast: index == groupedOutfits.count - 1,
                                reuseAction: { outfit in
                                    appContainer.pendingOutfitReuse = OutfitReuseRequest(
                                        itemIDs: outfit.items.map(\.id),
                                        scene: outfit.scene ?? "",
                                        notes: outfit.notes ?? ""
                                    )
                                    appContainer.selectedTab = .outfit
                                }
                            )
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .background(historyBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            Circle()
                .fill(HistoryPalette.secondaryContainer)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HistoryPalette.secondary)
                }

            Spacer()

            Text("Digital Atelier")
                .font(.headline.weight(.bold))
                .foregroundStyle(HistoryPalette.primary)

            Spacer()

            Button {} label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HistoryPalette.tertiary)
                    .frame(width: 34, height: 34)
                    .background(Color.clear)
            }
            .buttonStyle(.plain)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Style Journal")
                .font(.system(size: 30, weight: .heavy, design: .default))
                .foregroundStyle(HistoryPalette.textPrimary)
                .tracking(-0.8)

            Text("A curated collection of your aesthetic evolution.")
                .font(.subheadline)
                .foregroundStyle(HistoryPalette.textSecondary)
        }
        .padding(.top, 2)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(filterTitles.indices, id: \.self) { index in
                    let title = filterTitles[index]

                    Button {
                        selectedFilterIndex = index
                    } label: {
                        HStack(spacing: 6) {
                            if index == 3 {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 11, weight: .semibold))
                            }

                            Text(title.uppercased())
                        }
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedFilterIndex == index ? HistoryPalette.primary : HistoryPalette.surfaceHigh)
                        .foregroundStyle(selectedFilterIndex == index ? HistoryPalette.onPrimary : HistoryPalette.textSecondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var historyBackground: some View {
        HistoryPalette.background.ignoresSafeArea()
    }
}

private struct HistoryTimelineGroup: View {
    let date: Date
    let outfits: [Outfit]
    let isLast: Bool
    let reuseAction: (Outfit) -> Void

    private var dateText: String {
        date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(HistoryPalette.secondary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 12)

                Rectangle()
                    .fill(HistoryPalette.outline.opacity(0.24))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .opacity(isLast ? 0 : 1)
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 12) {
                Text(dateText.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 2)

                ForEach(outfits) { outfit in
                    NavigationLink {
                        OutfitDetailView(outfit: outfit)
                    } label: {
                        OutfitHistoryRow(
                            outfit: outfit,
                            reuseAction: { reuseAction(outfit) }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private enum HistoryPalette {
    static let background = Color(red: 0.988, green: 0.976, blue: 0.955)
    static let surfaceHigh = Color(red: 0.941, green: 0.933, blue: 0.902)
    static let primary = Color(red: 0.353, green: 0.412, blue: 0.322)
    static let secondary = Color(red: 0.506, green: 0.353, blue: 0.357)
    static let tertiary = Color(red: 0.431, green: 0.388, blue: 0.325)
    static let secondaryContainer = Color(red: 0.949, green: 0.867, blue: 0.804)
    static let textPrimary = Color(red: 0.220, green: 0.220, blue: 0.200)
    static let textSecondary = Color(red: 0.396, green: 0.396, blue: 0.369)
    static let outline = Color(red: 0.506, green: 0.506, blue: 0.478)
    static let onPrimary = Color.white
}

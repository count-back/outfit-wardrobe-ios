import SwiftUI
import SwiftData

struct OutfitHistoryView: View {
    @Query(sort: \Outfit.createdAt, order: .reverse) private var outfits: [Outfit]

    var body: some View {
        Group {
            if outfits.isEmpty {
                EmptyStateView(
                    title: "还没有搜配记录",
                    subtitle: "去搜配页保存几套方案，明天就能直接复用。",
                    systemImage: "clock.badge.xmark"
                )
            } else {
                List(outfits) { outfit in
                    NavigationLink {
                        OutfitDetailView(outfit: outfit)
                    } label: {
                        OutfitHistoryRow(outfit: outfit)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("搜配记录")
    }
}

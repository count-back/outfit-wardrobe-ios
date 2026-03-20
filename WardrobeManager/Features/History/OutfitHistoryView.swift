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
                List {
                    Section {
                        ForEach(outfits) { outfit in
                            NavigationLink {
                                OutfitDetailView(outfit: outfit)
                            } label: {
                                OutfitHistoryRow(outfit: outfit)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        historyHeader
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("搜配记录")
    }

    private var historyHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(outfits.count) 套记录")
                .font(.largeTitle.weight(.bold))

            Text("按时间倒序排列，先看最终分数，再看当时的单品构成。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .textCase(nil)
    }
}

import SwiftUI

struct RootTabView: View {
    @Environment(AppContainer.self) private var appContainer

    var body: some View {
        TabView(selection: Binding(
            get: { appContainer.selectedTab },
            set: { appContainer.selectedTab = $0 }
        )) {
            NavigationStack {
                WardrobeListView()
            }
            .tabItem {
                Label("衣柜", systemImage: "square.grid.2x2")
            }
            .tag(AppTab.wardrobe)

            NavigationStack {
                OutfitBuilderView()
            }
            .tabItem {
                Label("搜配", systemImage: "sparkles.rectangle.stack")
            }
            .tag(AppTab.outfit)

            NavigationStack {
                OutfitHistoryView()
            }
            .tabItem {
                Label("记录", systemImage: "clock.arrow.circlepath")
            }
            .tag(AppTab.history)
        }
        .tint(.accentColor)
    }
}

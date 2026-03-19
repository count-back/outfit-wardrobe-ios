import SwiftUI
import SwiftData

@main
struct WardrobeManagerApp: App {
    private let appContainer = AppContainer()

    var sharedModelContainer: ModelContainer = {
        do {
            let schema = Schema([
                ClothingItem.self,
                Outfit.self,
                OutfitItemSnapshot.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appContainer)
        }
        .modelContainer(sharedModelContainer)
    }
}

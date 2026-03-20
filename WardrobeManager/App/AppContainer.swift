import Foundation
import Observation

@Observable
final class AppContainer {
    var selectedTab: AppTab = .wardrobe
    var pendingOutfitReuse: OutfitReuseRequest?
    let imageProcessor = ClothingImageProcessor()
    let previewComposer = OutfitPreviewComposer()
    let scorer = OutfitScorer()
}

struct OutfitReuseRequest: Equatable {
    let itemIDs: [UUID]
    let scene: String
    let notes: String
}

enum AppTab: Hashable {
    case wardrobe
    case outfit
    case history
}

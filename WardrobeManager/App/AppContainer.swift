import Foundation
import Observation

@Observable
final class AppContainer {
    var selectedTab: AppTab = .wardrobe
    let imageProcessor = ClothingImageProcessor()
    let previewComposer = OutfitPreviewComposer()
    let scorer = OutfitScorer()
}

enum AppTab: Hashable {
    case wardrobe
    case outfit
    case history
}

import Foundation
import SwiftData

@Model
final class OutfitItemSnapshot {
    var id: UUID
    var itemID: UUID
    var name: String
    var categoryRawValue: String
    var color: String
    var style: String
    private var seasonRawValue: String

    init(item: ClothingItem) {
        self.id = UUID()
        self.itemID = item.id
        self.name = item.name
        self.categoryRawValue = item.category.rawValue
        self.color = item.color
        self.style = item.style
        self.seasonRawValue = item.season.rawValue
    }

    var category: ClothingCategory {
        ClothingCategory(rawValue: categoryRawValue) ?? .top
    }

    var season: Season {
        Season(rawValue: seasonRawValue) ?? .allSeason
    }
}

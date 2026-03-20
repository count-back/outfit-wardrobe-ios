import Foundation
import SwiftData

@Model
final class ClothingItem {
    var id: UUID
    var name: String
    private var categoryRawValue: String
    var color: String
    var style: String
    var location: String
    @Attribute(.externalStorage) var imageData: Data
    @Attribute(.externalStorage) var thumbnailData: Data?
    private var tagsRawValue: String
    private var seasonRawValue: String
    var purchasePrice: Double?
    var lastWornDate: Date?
    var wearCount: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        color: String,
        style: String,
        location: String,
        imageData: Data,
        thumbnailData: Data? = nil,
        tags: [String] = [],
        season: Season,
        purchasePrice: Double? = nil,
        lastWornDate: Date? = nil,
        wearCount: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = category.rawValue
        self.color = color
        self.style = style
        self.location = location
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.tagsRawValue = tags.joined(separator: ",")
        self.seasonRawValue = season.rawValue
        self.purchasePrice = purchasePrice
        self.lastWornDate = lastWornDate
        self.wearCount = wearCount
        self.createdAt = createdAt
    }

    var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryRawValue) ?? .top }
        set { categoryRawValue = newValue.rawValue }
    }

    var season: Season {
        get { Season(rawValue: seasonRawValue) ?? .allSeason }
        set { seasonRawValue = newValue.rawValue }
    }

    var tags: [String] {
        get {
            tagsRawValue
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            tagsRawValue = newValue.joined(separator: ",")
        }
    }
}

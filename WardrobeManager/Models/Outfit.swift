import Foundation
import SwiftData

@Model
final class Outfit {
    var id: UUID
    var name: String?
    @Relationship(deleteRule: .nullify) var items: [ClothingItem]
    @Relationship(deleteRule: .cascade) var snapshots: [OutfitItemSnapshot]
    @Attribute(.externalStorage) var previewImageData: Data
    var score: Int
    var scoreColor: Int
    var scoreStyle: Int
    var scoreSeason: Int
    var scoreFresh: Int
    var scoreLabel: String
    var scoreComment: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String? = nil,
        items: [ClothingItem],
        previewImageData: Data,
        score: OutfitScore,
        finalScore: Int? = nil,
        createdAt: Date = .now
    ) {
        let resolvedScore = min(max(finalScore ?? score.total, 0), 100)
        let summary = OutfitScore.summary(for: resolvedScore)

        self.id = id
        self.name = name
        self.items = items
        self.snapshots = items.map(OutfitItemSnapshot.init)
        self.previewImageData = previewImageData
        self.score = resolvedScore
        self.scoreColor = score.color
        self.scoreStyle = score.style
        self.scoreSeason = score.season
        self.scoreFresh = score.freshness
        self.scoreLabel = summary.label.rawValue
        self.scoreComment = summary.comment
        self.createdAt = createdAt
    }

    var resolvedScoreLabel: ScoreLabel {
        ScoreLabel(rawValue: scoreLabel) ?? .good
    }

    var displayName: String {
        if let name, !name.isEmpty {
            return name
        }

        let names = snapshots.map(\.name)
        if names.isEmpty {
            return "未命名搜配"
        }

        return names.prefix(2).joined(separator: " + ")
    }
}

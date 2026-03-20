import Foundation
import SwiftData

@Model
final class Outfit {
    var id: UUID = UUID()
    var name: String?
    var scene: String?
    var notes: String?
    @Relationship(deleteRule: .nullify) var items: [ClothingItem] = []
    @Relationship(deleteRule: .cascade) var snapshots: [OutfitItemSnapshot] = []
    @Attribute(.externalStorage) var previewImageData: Data = Data()
    var systemScore: Int = 0
    var finalScore: Int = 0
    var createdAt: Date = Date.now

    init(
        id: UUID = UUID(),
        name: String? = nil,
        scene: String? = nil,
        notes: String? = nil,
        items: [ClothingItem],
        previewImageData: Data,
        systemScore: OutfitScore,
        finalScore: Int? = nil,
        createdAt: Date = .now
    ) {
        let resolvedSystemScore = min(max(systemScore.total, 0), 100)
        let resolvedFinalScore = min(max(finalScore ?? resolvedSystemScore, 0), 100)

        self.id = id
        self.name = name
        self.scene = scene
        self.notes = notes
        self.items = items
        self.snapshots = items.map(OutfitItemSnapshot.init)
        self.previewImageData = previewImageData
        self.systemScore = resolvedSystemScore
        self.finalScore = resolvedFinalScore
        self.createdAt = createdAt
    }

    var finalScoreLabel: ScoreLabel {
        OutfitScore.summary(for: finalScore).label
    }

    var finalScoreComment: String {
        OutfitScore.summary(for: finalScore).comment
    }

    var scoreAdjustment: Int {
        finalScore - systemScore
    }

    var displayName: String {
        if let scene, !scene.isEmpty {
            return scene
        }

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

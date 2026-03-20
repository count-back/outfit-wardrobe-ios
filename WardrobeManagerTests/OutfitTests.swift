import XCTest
@testable import WardrobeManager

final class OutfitTests: XCTestCase {
    func testOutfitStoresSystemAndFinalScoreSeparately() {
        let item = ClothingItem(
            name: "白衬衫",
            category: .top,
            color: "白色",
            style: "通勤",
            location: "衣柜A",
            imageData: Data(),
            season: .spring
        )

        let outfit = Outfit(
            scene: "周五晚餐约会",
            notes: "搭配浅色外套会更稳妥。",
            items: [item],
            previewImageData: Data(),
            systemScore: OutfitScore(
                total: 78,
                color: 30,
                style: 20,
                season: 18,
                freshness: 10,
                label: .good,
                comment: "系统默认分"
            ),
            finalScore: 86
        )

        XCTAssertEqual(outfit.systemScore, 78)
        XCTAssertEqual(outfit.finalScore, 86)
        XCTAssertEqual(outfit.scoreAdjustment, 8)
        XCTAssertEqual(outfit.finalScoreLabel, .harmonious)
        XCTAssertEqual(outfit.scene, "周五晚餐约会")
        XCTAssertEqual(outfit.notes, "搭配浅色外套会更稳妥。")
        XCTAssertEqual(outfit.displayName, "周五晚餐约会")
    }

    func testOutfitDefaultsFinalScoreToSystemScore() {
        let item = ClothingItem(
            name: "黑西裤",
            category: .pants,
            color: "黑色",
            style: "通勤",
            location: "衣柜A",
            imageData: Data(),
            season: .allSeason
        )

        let outfit = Outfit(
            items: [item],
            previewImageData: Data(),
            systemScore: OutfitScore(
                total: 64,
                color: 26,
                style: 18,
                season: 10,
                freshness: 10,
                label: .mixed,
                comment: "系统默认分"
            )
        )

        XCTAssertEqual(outfit.systemScore, 64)
        XCTAssertEqual(outfit.finalScore, 64)
        XCTAssertEqual(outfit.scoreAdjustment, 0)
        XCTAssertEqual(outfit.finalScoreComment, "有一点混搭感，但整体仍然可接受。")
        XCTAssertEqual(outfit.displayName, "黑西裤")
    }
}

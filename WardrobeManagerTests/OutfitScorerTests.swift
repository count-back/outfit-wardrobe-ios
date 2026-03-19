import XCTest
@testable import WardrobeManager

final class OutfitScorerTests: XCTestCase {
    private let scorer = OutfitScorer()

    func testSameStyleAndNeutralColorsProduceHighScore() {
        let items = [
            ClothingItem(
                name: "奶油白针织",
                category: .top,
                color: "奶油白",
                style: "法式",
                location: "衣柜A",
                imageData: Data(),
                season: .spring
            ),
            ClothingItem(
                name: "米色半裙",
                category: .skirt,
                color: "米色",
                style: "法式",
                location: "衣柜A",
                imageData: Data(),
                season: .spring
            )
        ]

        let score = scorer.score(items: items)
        XCTAssertGreaterThanOrEqual(score.total, 80)
        XCTAssertTrue(score.label == .harmonious || score.label == .good)
    }

    func testConflictingStylesDropScore() {
        let items = [
            ClothingItem(
                name: "运动卫衣",
                category: .top,
                color: "红色",
                style: "运动",
                location: "衣柜A",
                imageData: Data(),
                season: .winter
            ),
            ClothingItem(
                name: "法式长裙",
                category: .skirt,
                color: "绿色",
                style: "法式",
                location: "衣柜A",
                imageData: Data(),
                season: .summer
            )
        ]

        let score = scorer.score(items: items)
        XCTAssertLessThanOrEqual(score.style, 10)
        XCTAssertLessThan(score.total, 70)
    }
}

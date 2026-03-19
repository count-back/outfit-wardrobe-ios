import Foundation

struct OutfitScore: Equatable {
    let total: Int
    let color: Int
    let style: Int
    let season: Int
    let freshness: Int
    let label: ScoreLabel
    let comment: String

    static func summary(for total: Int) -> (label: ScoreLabel, comment: String) {
        switch total {
        case 85...100:
            return (.harmonious, "整体关系自然，已经是一套可以直接出门的搜配。")
        case 70...84:
            return (.good, "整体关系自然，已经是一套可以直接出门的搜配。")
        case 55...69:
            return (.mixed, "有一点混搭感，但整体仍然可接受。")
        default:
            return (.conflict, "风格或色彩存在冲突，建议换掉一件主单品再试试。")
        }
    }
}

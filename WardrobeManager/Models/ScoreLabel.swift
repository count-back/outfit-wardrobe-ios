import SwiftUI

enum ScoreLabel: String, Codable {
    case harmonious = "色彩和谐"
    case good = "搜配不错"
    case mixed = "轻微混搭"
    case conflict = "风格冲突"

    var tint: Color {
        switch self {
        case .harmonious:
            return .green
        case .good:
            return .teal
        case .mixed:
            return .orange
        case .conflict:
            return .red
        }
    }
}

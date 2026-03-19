import Foundation

enum Season: String, Codable, CaseIterable, Identifiable {
    case spring = "春"
    case summer = "夏"
    case autumn = "秋"
    case winter = "冬"
    case allSeason = "四季"

    var id: String { rawValue }
}

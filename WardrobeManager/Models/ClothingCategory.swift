import Foundation

enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case top = "上衣"
    case pants = "裤子"
    case skirt = "裙子"
    case outerwear = "外套"
    case shoes = "鞋子"
    case accessory = "配件"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .top:
            return "tshirt"
        case .pants:
            return "figure.walk"
        case .skirt:
            return "figure.dress.line.vertical.figure"
        case .outerwear:
            return "hanger"
        case .shoes:
            return "shoeprints.fill"
        case .accessory:
            return "sparkles"
        }
    }

    static let primaryFilterCategories: [ClothingCategory] = [.top, .pants, .skirt, .outerwear]
}

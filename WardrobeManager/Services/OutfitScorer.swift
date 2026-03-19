import Foundation

struct OutfitScorer {
    func score(items: [ClothingItem]) -> OutfitScore {
        let colorScore = scoreColors(items.map(\.color))
        let styleScore = scoreStyles(items.map(\.style))
        let seasonScore = scoreSeasons(items.map(\.season))
        let freshnessScore = scoreFreshness(items)
        let total = min(100, colorScore + styleScore + seasonScore + freshnessScore)
        let summary = OutfitScore.summary(for: total)

        return OutfitScore(
            total: total,
            color: colorScore,
            style: styleScore,
            season: seasonScore,
            freshness: freshnessScore,
            label: summary.label,
            comment: summary.comment
        )
    }

    private func scoreColors(_ colors: [String]) -> Int {
        let normalized = colors.map(normalizeColor(_:))
        let unique = Set(normalized)

        if unique.count <= 1 {
            return 38
        }

        if unique.allSatisfy(isNeutralColor(_:)) {
            return 34
        }

        if unique.contains(where: isNeutralColor(_:)) && unique.count <= 3 {
            return 32
        }

        if containsComplementaryPair(in: unique) {
            return 24
        }

        if unique.count >= 4 && !unique.contains(where: isNeutralColor(_:)) {
            return 10
        }

        return 26
    }

    private func scoreStyles(_ styles: [String]) -> Int {
        let normalized = styles.map(normalizeStyle(_:))
        let unique = Set(normalized)

        if unique.count <= 1 {
            return 30
        }

        if unique.count == 2, areAdjacentStyles(Array(unique)) {
            return 20
        }

        if unique.count <= 3 {
            return 10
        }

        return 0
    }

    private func scoreSeasons(_ seasons: [Season]) -> Int {
        let unique = Set(seasons)

        if unique.count == 1 {
            return 20
        }

        if unique.contains(.allSeason) {
            return 15
        }

        return 10
    }

    private func scoreFreshness(_ items: [ClothingItem]) -> Int {
        let threshold = Calendar.current.date(byAdding: .day, value: -60, to: .now) ?? .distantPast

        return items.contains {
            guard let lastWornDate = $0.lastWornDate else { return true }
            return lastWornDate < threshold
        } ? 10 : 0
    }

    private func normalizeColor(_ value: String) -> String {
        let mapping: [String: String] = [
            "奶油白": "白色",
            "米白": "白色",
            "米色": "白色",
            "灰白": "白色",
            "炭黑": "黑色",
            "深灰": "灰色",
            "路蒙蓝": "蓝色",
            "深蓝": "蓝色",
            "浅蓝": "蓝色",
            "酒红": "红色",
            "浅紫": "紫色",
            "军绿": "绿色",
            "卡其": "棕色"
        ]

        return mapping[value.trimmingCharacters(in: .whitespacesAndNewlines)] ?? value
    }

    private func normalizeStyle(_ value: String) -> String {
        let mapping: [String: String] = [
            "简约通勤": "通勤",
            "韩系": "韩系",
            "日杂": "日系",
            "法式优雅": "法式",
            "极简": "简约",
            "运动休闲": "运动"
        ]

        return mapping[value.trimmingCharacters(in: .whitespacesAndNewlines)] ?? value
    }

    private func isNeutralColor(_ color: String) -> Bool {
        ["白色", "黑色", "灰色", "棕色", "米色", "卡其"].contains(color)
    }

    private func containsComplementaryPair(in colors: Set<String>) -> Bool {
        let pairs: [Set<String>] = [
            ["蓝色", "橙色"],
            ["红色", "绿色"],
            ["黄色", "紫色"]
        ]

        return pairs.contains { $0.isSubset(of: colors) }
    }

    private func areAdjacentStyles(_ styles: [String]) -> Bool {
        let adjacency: [String: Set<String>] = [
            "日系": ["韩系", "简约", "通勤"],
            "韩系": ["日系", "简约"],
            "法式": ["简约", "通勤"],
            "简约": ["法式", "韩系", "日系", "通勤"],
            "通勤": ["法式", "简约", "日系"]
        ]

        guard styles.count == 2 else { return false }
        return adjacency[styles[0], default: []].contains(styles[1]) || adjacency[styles[1], default: []].contains(styles[0])
    }
}

import SwiftUI

struct ScoreBadge: View {
    let label: ScoreLabel

    var body: some View {
        Text(label.rawValue)
            .font(.system(.caption2, design: .rounded, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(label.tint.opacity(0.16))
            .foregroundStyle(label.tint)
            .clipShape(Capsule())
    }
}

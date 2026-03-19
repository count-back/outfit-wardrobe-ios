import SwiftUI

struct ScoreBadge: View {
    let label: ScoreLabel

    var body: some View {
        Text(label.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(label.tint.opacity(0.14))
            .foregroundStyle(label.tint)
            .clipShape(Capsule())
    }
}

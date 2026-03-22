import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AtelierTheme.tertiary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .atelierCard(background: AtelierTheme.surfaceLow)
    }
}

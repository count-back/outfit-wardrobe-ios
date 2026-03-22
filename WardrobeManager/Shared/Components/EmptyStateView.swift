import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AtelierTheme.secondary)
                .frame(width: 58, height: 58)
                .background(AtelierTheme.secondaryContainer, in: Circle())

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AtelierTheme.textPrimary)

            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AtelierTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .atelierCard(background: AtelierTheme.surfaceLow, cornerRadius: 36, padding: 28)
    }
}

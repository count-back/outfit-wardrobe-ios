import SwiftUI

struct RootTabView: View {
    @Environment(AppContainer.self) private var appContainer

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: Binding(
                get: { appContainer.selectedTab },
                set: { appContainer.selectedTab = $0 }
            )) {
                NavigationStack {
                    WardrobeListView()
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.wardrobe)

                NavigationStack {
                    OutfitBuilderView()
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.outfit)

                NavigationStack {
                    OutfitHistoryView()
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.history)
            }
            .tint(AtelierTheme.primary)
            .atelierPageBackground()

            AtelierTabBar(selectedTab: Binding(
                get: { appContainer.selectedTab },
                set: { appContainer.selectedTab = $0 }
            ))
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
        .overlay(alignment: .top) {
            if let feedback = appContainer.operationFeedback {
                OperationFeedbackBanner(feedback: feedback)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture {
                        appContainer.hideOperationFeedback()
                    }
            }
        }
        .animation(.smooth, value: appContainer.operationFeedback)
    }
}

private struct OperationFeedbackBanner: View {
    let feedback: OperationFeedback

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: feedback.style == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.bold))

            Text(feedback.message)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(backgroundColor, in: Capsule())
        .shadow(color: AtelierTheme.shadow, radius: 16, y: 8)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var backgroundColor: Color {
        switch feedback.style {
        case .success:
            return AtelierTheme.primary.opacity(0.96)
        case .error:
            return Color(red: 0.68, green: 0.25, blue: 0.15).opacity(0.96)
        }
    }
}

private struct AtelierTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack {
            tabItem(title: "CLOSET", icon: "hanger", tab: .wardrobe)
            Spacer()
            tabItem(title: "MIX & MATCH", icon: "figure.stand", tab: .outfit)
            Spacer()
            tabItem(title: "JOURNAL", icon: "book.closed", tab: .history)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(AtelierTheme.surface.opacity(0.72))
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        .shadow(color: AtelierTheme.shadow, radius: 24, y: 12)
    }

    private func tabItem(title: String, icon: String, tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(0.8)
            }
            .foregroundStyle(selectedTab == tab ? AtelierTheme.primary : AtelierTheme.tertiary.opacity(0.7))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

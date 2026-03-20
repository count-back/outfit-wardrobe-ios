import SwiftUI

struct RootTabView: View {
    @Environment(AppContainer.self) private var appContainer

    var body: some View {
        TabView(selection: Binding(
            get: { appContainer.selectedTab },
            set: { appContainer.selectedTab = $0 }
        )) {
            NavigationStack {
                WardrobeListView()
            }
            .tabItem {
                Label("衣柜", systemImage: "square.grid.2x2")
            }
            .tag(AppTab.wardrobe)

            NavigationStack {
                OutfitBuilderView()
            }
            .tabItem {
                Label("搜配", systemImage: "sparkles.rectangle.stack")
            }
            .tag(AppTab.outfit)

            NavigationStack {
                OutfitHistoryView()
            }
            .tabItem {
                Label("记录", systemImage: "clock.arrow.circlepath")
            }
            .tag(AppTab.history)
        }
        .tint(.accentColor)
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
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var backgroundColor: Color {
        switch feedback.style {
        case .success:
            return Color.green.opacity(0.95)
        case .error:
            return Color.red.opacity(0.95)
        }
    }
}

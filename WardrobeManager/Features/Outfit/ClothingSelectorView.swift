import SwiftUI

struct ClothingSelectorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let items: [ClothingItem]
    @Binding var selectedItem: ClothingItem?

    var body: some View {
        ScrollView(showsIndicators: false) {
            if items.isEmpty {
                EmptyStateView(
                    title: "暂无可选单品",
                    subtitle: "先去衣柜页添加这个分类的衣物。",
                    systemImage: "square.stack.3d.up.slash"
                )
                .padding(.top, 56)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            selectedItem = item
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(AtelierTheme.surfaceLow)
                                        .frame(width: 82, height: 96)

                                    if let image = item.thumbnailData?.swiftUIImage ?? item.imageData.swiftUIImage {
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .padding(10)
                                    } else {
                                        Image(systemName: item.category.icon)
                                            .font(.system(size: 24, weight: .light))
                                            .foregroundStyle(AtelierTheme.secondary)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.category.rawValue.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .tracking(1.6)
                                        .foregroundStyle(AtelierTheme.tertiary)

                                    Text(item.name)
                                        .font(.system(.headline, design: .rounded, weight: .semibold))
                                        .foregroundStyle(AtelierTheme.textPrimary)

                                    Text("\(item.color) · \(item.style)")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(AtelierTheme.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: selectedItem?.id == item.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(selectedItem?.id == item.id ? AtelierTheme.primary : AtelierTheme.outline.opacity(0.6))
                            }
                            .padding(14)
                            .background(AtelierTheme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .shadow(color: AtelierTheme.shadow, radius: 14, y: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
        .atelierPageBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if selectedItem != nil {
                    Button("清除") {
                        selectedItem = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

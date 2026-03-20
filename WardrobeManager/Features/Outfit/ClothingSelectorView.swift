import SwiftUI

struct ClothingSelectorView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let items: [ClothingItem]
    @Binding var selectedItem: ClothingItem?

    var body: some View {
        Group {
            if items.isEmpty {
                EmptyStateView(
                    title: "暂无可选单品",
                    subtitle: "先去衣柜页添加这个分类的衣物。",
                    systemImage: "square.stack.3d.up.slash"
                )
            } else {
                List(items) { item in
                    Button {
                        selectedItem = item
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            if let image = item.thumbnailData?.swiftUIImage ?? item.imageData.swiftUIImage {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 52, height: 52)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .foregroundStyle(.primary)
                                Text("\(item.color) · \(item.style)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedItem?.id == item.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
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

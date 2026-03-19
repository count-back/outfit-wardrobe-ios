import SwiftUI
import SwiftData
import UIKit

struct AddClothingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer

    @State private var name = ""
    @State private var category: ClothingCategory = .top
    @State private var color = ""
    @State private var style = ""
    @State private var location = ""
    @State private var season: Season = .allSeason
    @State private var tagsText = ""
    @State private var purchasePriceText = ""
    @State private var rawImage: UIImage?
    @State private var processedImageData: Data?
    @State private var selectedImageVersion: SelectedImageVersion = .original
    @State private var isPresentingCamera = false
    @State private var isPresentingPhotoLibrary = false
    @State private var isProcessingImage = false
    @State private var imageProcessingStatus: ImageProcessingStatus?
    @State private var errorMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !color.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !style.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedImageData != nil
    }

    var body: some View {
        Form {
            Section("衣物图片") {
                VStack(spacing: 14) {
                    preview

                    HStack(spacing: 12) {
                        Button("拍照添加") {
                            isPresentingCamera = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                        Button("从相册导入") {
                            isPresentingPhotoLibrary = true
                        }
                        .buttonStyle(.bordered)
                    }

                    if isProcessingImage {
                        ProgressView("正在处理图片…")
                    }

                    if showsImageVersionPicker {
                        Picker("保存版本", selection: $selectedImageVersion) {
                            ForEach(SelectedImageVersion.allCases) { version in
                                Text(version.title).tag(version)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if let imageProcessingStatus {
                        Text(imageProcessingStatus.message)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(imageProcessingStatus.tint)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(imageProcessingStatus.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Section("基本信息") {
                TextField("名称", text: $name)
                Picker("分类", selection: $category) {
                    ForEach(ClothingCategory.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                TextField("主色，例如：奶油白", text: $color)
                TextField("风格，例如：法式 / 通勤", text: $style)
                TextField("存放位置", text: $location)
                Picker("季节", selection: $season) {
                    ForEach(Season.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                TextField("标签，使用逗号分隔", text: $tagsText)
                TextField("购买价格（可选）", text: $purchasePriceText)
                    .keyboardType(.decimalPad)
            }
        }
        .navigationTitle("添加衣物")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    saveItem()
                }
                .disabled(!canSave)
            }
        }
        .sheet(isPresented: $isPresentingCamera) {
            ImagePicker(sourceType: .camera) { image in
                handlePickedImage(image)
            }
        }
        .sheet(isPresented: $isPresentingPhotoLibrary) {
            ImagePicker(sourceType: .photoLibrary) { image in
                handlePickedImage(image)
            }
        }
        .alert("保存失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        ), actions: {
            Button("知道了") {
                errorMessage = nil
            }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 240)

            if let image = previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 220)
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 32))
                    Text("先拍一张衣物照片")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private var previewImage: UIImage? {
        if selectedImageVersion == .cutout,
           let processedImageData,
           let image = UIImage(data: processedImageData) {
            return image
        }
        return rawImage
    }

    private var selectedImageData: Data? {
        switch selectedImageVersion {
        case .original:
            return rawImage?.pngData()
        case .cutout:
            return processedImageData
        }
    }

    private var showsImageVersionPicker: Bool {
        rawImage != nil && processedImageData != nil && imageProcessingStatus == .success
    }

    private func handlePickedImage(_ image: UIImage) {
        rawImage = image
        selectedImageVersion = .original
        processedImageData = nil
        imageProcessingStatus = nil
        isProcessingImage = true

        Task {
            do {
                let preparedImage = try await appContainer.imageProcessor.prepareImage(from: image)
                await MainActor.run {
                    processedImageData = preparedImage.data
                    imageProcessingStatus = preparedImage.didRemoveBackground ? .success : .fallback
                    selectedImageVersion = preparedImage.didRemoveBackground ? .cutout : .original
                    isProcessingImage = false
                }
            } catch {
                await MainActor.run {
                    processedImageData = nil
                    imageProcessingStatus = .fallback
                    selectedImageVersion = .original
                    isProcessingImage = false
                }
            }
        }
    }

    private func saveItem() {
        guard let selectedImageData else { return }

        let item = ClothingItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            color: color.trimmingCharacters(in: .whitespacesAndNewlines),
            style: style.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: selectedImageData,
            tags: tagsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            season: season,
            purchasePrice: Double(purchasePriceText)
        )

        modelContext.insert(item)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "衣物保存失败，请稍后再试。"
        }
    }
}

private enum SelectedImageVersion: String, CaseIterable, Identifiable {
    case original
    case cutout

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original:
            return "原图"
        case .cutout:
            return "抠图"
        }
    }
}

private enum ImageProcessingStatus {
    case success
    case fallback

    var message: String {
        switch self {
        case .success:
            return "已生成抠图，可切换预览后再保存。"
        case .fallback:
            return "未能自动抠图，当前将使用原图。"
        }
    }

    var tint: Color {
        switch self {
        case .success:
            return .green
        case .fallback:
            return .orange
        }
    }
}

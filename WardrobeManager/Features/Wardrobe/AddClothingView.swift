import SwiftUI
import SwiftData
import UIKit

struct AddClothingView: View {
    enum Mode {
        case add
        case edit(ClothingItem)

        var title: String {
            switch self {
            case .add:
                return "添加衣物"
            case .edit:
                return "编辑衣物"
            }
        }

        var saveButtonTitle: String {
            switch self {
            case .add:
                return "保存"
            case .edit:
                return "更新"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppContainer.self) private var appContainer

    private let mode: Mode
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
    @State private var processedThumbnailData: Data?
    @State private var selectedImageVersion: SelectedImageVersion = .original
    @State private var isPresentingCamera = false
    @State private var isPresentingPhotoLibrary = false
    @State private var isProcessingImage = false
    @State private var imageProcessingStatus: ImageProcessingStatus?
    @State private var saveSuccessMessage: String?
    @State private var errorMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !color.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !style.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedImageData != nil
    }

    init(mode: Mode = .add) {
        self.mode = mode

        switch mode {
        case .add:
            _name = State(initialValue: "")
            _category = State(initialValue: .top)
            _color = State(initialValue: "")
            _style = State(initialValue: "")
            _location = State(initialValue: "")
            _season = State(initialValue: .allSeason)
            _tagsText = State(initialValue: "")
            _purchasePriceText = State(initialValue: "")
            _rawImage = State(initialValue: nil)
            _processedImageData = State(initialValue: nil)
            _processedThumbnailData = State(initialValue: nil)
            _selectedImageVersion = State(initialValue: .original)
        case let .edit(item):
            _name = State(initialValue: item.name)
            _category = State(initialValue: item.category)
            _color = State(initialValue: item.color)
            _style = State(initialValue: item.style)
            _location = State(initialValue: item.location)
            _season = State(initialValue: item.season)
            _tagsText = State(initialValue: item.tags.joined(separator: ", "))
            if let purchasePrice = item.purchasePrice {
                _purchasePriceText = State(initialValue: String(purchasePrice))
            } else {
                _purchasePriceText = State(initialValue: "")
            }
            _rawImage = State(initialValue: UIImage(data: item.imageData))
            _processedImageData = State(initialValue: nil)
            _processedThumbnailData = State(initialValue: item.thumbnailData)
            _selectedImageVersion = State(initialValue: .original)
        }
    }

    var body: some View {
        Form {
            if let saveSuccessMessage {
                Section("保存结果") {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(saveSuccessMessage)
                                .font(.subheadline.weight(.semibold))
                            Text("表单已清空，可以继续录入下一件。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

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
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(primaryActionTitle) {
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
        processedThumbnailData = nil
        imageProcessingStatus = nil
        isProcessingImage = true

        Task {
            do {
                let preparedImage = try await appContainer.imageProcessor.prepareImage(from: image)
                await MainActor.run {
                    processedImageData = preparedImage.data
                    processedThumbnailData = preparedImage.thumbnailData
                    imageProcessingStatus = preparedImage.didRemoveBackground ? .success : .fallback
                    selectedImageVersion = preparedImage.didRemoveBackground ? .cutout : .original
                    isProcessingImage = false
                }
            } catch {
                await MainActor.run {
                    processedImageData = nil
                    processedThumbnailData = nil
                    imageProcessingStatus = .fallback
                    selectedImageVersion = .original
                    isProcessingImage = false
                }
            }
        }
    }

    private func saveItem() {
        guard let selectedImage = previewImage else { return }

        let preserveAlpha = selectedImageVersion == .cutout
        let selectedAsset: ProcessedClothingImageAsset?

        if preserveAlpha {
            guard
                let processedImageData,
                let processedThumbnailData
            else {
                return
            }

            selectedAsset = ProcessedClothingImageAsset(
                data: processedImageData,
                thumbnailData: processedThumbnailData
            )
        } else {
            selectedAsset = appContainer.imageProcessor.makeStorageAsset(
                from: selectedImage,
                preserveAlpha: false
            )
        }

        guard let selectedAsset else { return }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        switch mode {
        case .add:
            let item = ClothingItem(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                color: color.trimmingCharacters(in: .whitespacesAndNewlines),
                style: style.trimmingCharacters(in: .whitespacesAndNewlines),
                location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                imageData: selectedAsset.data,
                thumbnailData: selectedAsset.thumbnailData,
                tags: tags,
                season: season,
                purchasePrice: Double(purchasePriceText)
            )

            modelContext.insert(item)
        case let .edit(item):
            item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            item.category = category
            item.color = color.trimmingCharacters(in: .whitespacesAndNewlines)
            item.style = style.trimmingCharacters(in: .whitespacesAndNewlines)
            item.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
            item.imageData = selectedAsset.data
            item.thumbnailData = selectedAsset.thumbnailData
            item.tags = tags
            item.season = season
            item.purchasePrice = Double(purchasePriceText)
        }

        do {
            try modelContext.save()
            errorMessage = nil

            switch mode {
            case .add:
                clearFormForNextItem()
                saveSuccessMessage = "衣物已保存"
                appContainer.showOperationFeedback(
                    OperationFeedback(message: "衣物已保存", style: .success)
                )
            case .edit:
                saveSuccessMessage = nil
                appContainer.showOperationFeedback(
                    OperationFeedback(message: "衣物已更新", style: .success)
                )
                dismiss()
            }
        } catch {
            saveSuccessMessage = nil
            errorMessage = "衣物保存失败，请稍后再试。"
            appContainer.showOperationFeedback(
                OperationFeedback(message: "衣物保存失败，请稍后再试。", style: .error),
                autoDismissAfter: 3_000_000_000
            )
        }
    }

    private var primaryActionTitle: String {
        switch mode {
        case .add:
            return "保存并继续"
        case .edit:
            return mode.saveButtonTitle
        }
    }

    private func clearFormForNextItem() {
        name = ""
        category = .top
        color = ""
        style = ""
        location = ""
        season = .allSeason
        tagsText = ""
        purchasePriceText = ""
        rawImage = nil
        processedImageData = nil
        processedThumbnailData = nil
        selectedImageVersion = .original
        isPresentingCamera = false
        isPresentingPhotoLibrary = false
        isProcessingImage = false
        imageProcessingStatus = nil
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

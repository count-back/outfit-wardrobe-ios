import AVFoundation
import UIKit

struct OutfitPreviewComposer {
    func composePreview(for items: [ClothingItem], canvasSize: CGSize = CGSize(width: 720, height: 1080)) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            let canvasRect = CGRect(origin: .zero, size: canvasSize)
            let cardRect = CGRect(x: 48, y: 44, width: canvasSize.width - 96, height: canvasSize.height - 88)
            let previewRect = CGRect(x: cardRect.minX + 74, y: cardRect.minY + 118, width: cardRect.width - 148, height: cardRect.height - 270)

            drawBackground(in: cgContext, rect: canvasRect)
            drawCard(in: cgContext, rect: cardRect)
            drawHeader(for: items, in: cardRect)
            drawPreviewBase(in: cgContext, rect: previewRect)
            drawLook(for: items, in: previewRect)
            drawFooter(for: items, in: cardRect)
        }

        return image.jpegData(compressionQuality: 0.92)
    }

    private func drawBackground(in context: CGContext, rect: CGRect) {
        let colors = [
            UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1).cgColor,
            UIColor(red: 0.90, green: 0.93, blue: 0.98, alpha: 1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])

        if let gradient {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.minX, y: rect.minY),
                end: CGPoint(x: rect.maxX, y: rect.maxY),
                options: []
            )
        }

        context.saveGState()
        context.setFillColor(UIColor.white.withAlphaComponent(0.28).cgColor)
        context.fillEllipse(in: CGRect(x: rect.minX + 22, y: rect.minY + 70, width: 220, height: 150))
        context.fillEllipse(in: CGRect(x: rect.maxX - 280, y: rect.maxY - 240, width: 210, height: 160))
        context.restoreGState()
    }

    private func drawCard(in context: CGContext, rect: CGRect) {
        let cardPath = UIBezierPath(roundedRect: rect, cornerRadius: 40)

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 26), blur: 38, color: UIColor.black.withAlphaComponent(0.10).cgColor)
        UIColor.white.withAlphaComponent(0.80).setFill()
        cardPath.fill()
        context.restoreGState()

        UIColor.white.withAlphaComponent(0.40).setStroke()
        cardPath.lineWidth = 1.2
        cardPath.stroke()
    }

    private func drawHeader(for items: [ClothingItem], in rect: CGRect) {
        let title = "On-Body Preview"
        let subtitle = items.map(\.name).joined(separator: " / ")

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]

        title.draw(in: CGRect(x: rect.minX + 30, y: rect.minY + 28, width: 250, height: 28), withAttributes: titleAttributes)
        subtitle.draw(in: CGRect(x: rect.minX + 30, y: rect.minY + 60, width: rect.width - 60, height: 22), withAttributes: subtitleAttributes)
    }

    private func drawPreviewBase(in context: CGContext, rect: CGRect) {
        let centerX = rect.midX

        context.saveGState()
        context.setFillColor(UIColor.white.withAlphaComponent(0.42).cgColor)
        context.fillEllipse(in: CGRect(x: centerX - 132, y: rect.maxY - 22, width: 264, height: 24))

        context.setFillColor(UIColor(red: 0.92, green: 0.94, blue: 0.98, alpha: 0.16).cgColor)
        let torso = UIBezierPath(roundedRect: CGRect(x: centerX - 102, y: rect.minY + 42, width: 204, height: 348), cornerRadius: 94)
        torso.fill()

        let leftLeg = UIBezierPath(roundedRect: CGRect(x: centerX - 58, y: rect.minY + 368, width: 38, height: 248), cornerRadius: 18)
        let rightLeg = UIBezierPath(roundedRect: CGRect(x: centerX + 20, y: rect.minY + 368, width: 38, height: 248), cornerRadius: 18)
        leftLeg.fill()
        rightLeg.fill()
        context.restoreGState()
    }

    private func drawLook(for items: [ClothingItem], in rect: CGRect) {
        let topItem = items.first(where: { $0.category == .top })
        let bottomItem = items.first(where: { $0.category == .pants || $0.category == .skirt })
        let outerwear = items.first(where: { $0.category == .outerwear })
        let shoes = items.first(where: { $0.category == .shoes })
        let accessory = items.first(where: { $0.category == .accessory })

        let centerX = rect.midX
        let shoulderRect = CGRect(x: centerX - 162, y: rect.minY + 30, width: 324, height: 330)
        let outerwearRect = CGRect(x: centerX - 176, y: rect.minY + 18, width: 352, height: 352)
        let pantsRect = CGRect(x: centerX - 122, y: rect.minY + 282, width: 244, height: 352)
        let skirtRect = CGRect(x: centerX - 168, y: rect.minY + 270, width: 336, height: 280)
        let shoesRect = CGRect(x: centerX - 122, y: rect.maxY - 92, width: 244, height: 74)
        let accessoryRect = CGRect(x: centerX + 114, y: rect.minY + 88, width: 82, height: 82)

        if let bottomItem {
            let targetRect = bottomItem.category == .skirt ? skirtRect : pantsRect
            drawGarment(bottomItem, in: targetRect, verticalAnchor: 0.0, scale: 1.05, alpha: 0.98)
        }

        drawGarment(topItem, in: shoulderRect, verticalAnchor: 0.0, scale: 1.06, alpha: 0.99)
        drawGarment(outerwear, in: outerwearRect, verticalAnchor: 0.0, scale: 1.08, alpha: 0.90)
        drawShoes(shoes, in: shoesRect)
        drawAccessory(accessory, in: accessoryRect)
    }

    private func drawGarment(_ item: ClothingItem?, in rect: CGRect, verticalAnchor: CGFloat, scale: CGFloat, alpha: CGFloat) {
        guard
            let item,
            let image = preparedPreviewImage(from: item.imageData)
        else {
            return
        }

        let fitted = anchoredRect(for: image.size, inside: rect, verticalAnchor: verticalAnchor, scale: scale)
        let shadowRect = fitted.offsetBy(dx: 0, dy: 10)

        UIColor.black.withAlphaComponent(0.08).setFill()
        UIBezierPath(roundedRect: shadowRect.insetBy(dx: 16, dy: 16), cornerRadius: 24).fill()
        image.draw(in: fitted, blendMode: .normal, alpha: alpha)
    }

    private func drawShoes(_ item: ClothingItem?, in rect: CGRect) {
        guard
            let item,
            let image = preparedPreviewImage(from: item.imageData)
        else {
            return
        }

        let fitted = anchoredRect(for: image.size, inside: rect, verticalAnchor: 0.5, scale: 1.06)
        image.draw(in: fitted, blendMode: .normal, alpha: 0.98)
    }

    private func drawAccessory(_ item: ClothingItem?, in rect: CGRect) {
        guard
            let item,
            let image = preparedPreviewImage(from: item.imageData)
        else {
            return
        }

        let bubble = UIBezierPath(ovalIn: rect.insetBy(dx: -10, dy: -10))
        UIColor.white.withAlphaComponent(0.72).setFill()
        bubble.fill()

        let fitted = AVMakeRect(aspectRatio: image.size, insideRect: rect)
        image.draw(in: fitted, blendMode: .normal, alpha: 0.95)
    }

    private func drawFooter(for items: [ClothingItem], in rect: CGRect) {
        let summary = items
            .map { "\($0.category.rawValue)：\($0.name)" }
            .joined(separator: "  ·  ")

        let footerRect = CGRect(x: rect.minX + 28, y: rect.maxY - 78, width: rect.width - 56, height: 44)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel,
            .paragraphStyle: paragraph
        ]

        summary.draw(in: footerRect, withAttributes: attributes)
    }

    private func anchoredRect(for imageSize: CGSize, inside rect: CGRect, verticalAnchor: CGFloat, scale: CGFloat) -> CGRect {
        let fitted = AVMakeRect(aspectRatio: imageSize, insideRect: rect)
        let scaledWidth = fitted.width * scale
        let scaledHeight = fitted.height * scale
        let x = rect.midX - scaledWidth / 2
        let availableY = max(rect.height - scaledHeight, 0)
        let y = rect.minY + (availableY * verticalAnchor)

        return CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
    }

    private func preparedPreviewImage(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        if image.hasMeaningfulAlphaChannel {
            return image.previewTrimmedTransparentBounds()
        }
        return image
    }
}

private extension UIImage {
    var hasMeaningfulAlphaChannel: Bool {
        guard let alphaInfo = cgImage?.alphaInfo else { return false }

        switch alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        default:
            return false
        }
    }

    func previewTrimmedTransparentBounds(alphaThreshold: UInt8 = 8) -> UIImage {
        guard let cgImage else { return self }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return self
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return self }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var foundOpaque = false

        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[(y * bytesPerRow) + (x * bytesPerPixel) + 3]
                if alpha > alphaThreshold {
                    foundOpaque = true
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard foundOpaque else { return self }

        let padding = 10
        let cropX = max(minX - padding, 0)
        let cropY = max(minY - padding, 0)
        let cropWidth = min(maxX + padding + 1, width) - cropX
        let cropHeight = min(maxY + padding + 1, height) - cropY
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)

        guard let cropped = cgImage.cropping(to: cropRect.integral) else { return self }
        return UIImage(cgImage: cropped, scale: scale, orientation: .up)
    }
}

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

struct ProcessedClothingImage {
    let data: Data
    let didRemoveBackground: Bool
}

struct ClothingImageProcessor {
    func prepareImage(from image: UIImage) async throws -> ProcessedClothingImage {
        let normalizedImage = image.normalizedForVision()
        let visionCutout: UIImage?

        do {
            visionCutout = try await removeBackground(from: normalizedImage)
        } catch {
            visionCutout = nil
        }

        if let cutout = processedCutout(from: visionCutout, original: normalizedImage),
           let pngData = cutout.pngData() {
            return ProcessedClothingImage(data: pngData, didRemoveBackground: true)
        }

        if let fallbackCutout = processedCutout(
            from: removeFlatBackground(from: normalizedImage, luminanceThreshold: 58, colorDistanceThreshold: 110),
            original: normalizedImage
        ),
           let pngData = fallbackCutout.pngData() {
            return ProcessedClothingImage(data: pngData, didRemoveBackground: true)
        }

        guard let fallback = normalizedImage.pngData() else {
            throw ClothingImageProcessorError.encodingFailed
        }

        return ProcessedClothingImage(data: fallback, didRemoveBackground: false)
    }

    private func processedCutout(from candidate: UIImage?, original: UIImage) -> UIImage? {
        guard
            let candidate,
            candidate.hasMeaningfulBackgroundRemoval(comparedTo: original)
        else {
            return nil
        }

        return candidate.trimmedTransparentBounds()
    }

    private func removeBackground(from image: UIImage) async throws -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        guard
            let result = request.results?.first,
            let maskBuffer = try? result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
        else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let context = CIContext()
        let clearBackground = CIImage(color: .clear).cropped(to: ciImage.extent)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.inputImage = ciImage
        blendFilter.backgroundImage = clearBackground
        blendFilter.maskImage = maskImage

        guard let outputImage = blendFilter.outputImage,
              let output = context.createCGImage(outputImage, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: output, scale: image.scale, orientation: .up)
    }

    private func removeFlatBackground(
        from image: UIImage,
        luminanceThreshold: Int,
        colorDistanceThreshold: Int
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

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
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }

        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        let backgroundColor = averageBorderColor(
            pixels: pixels,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow
        )

        for y in 0..<height {
            for x in 0..<width {
                let isBorderPixel = x == 0 || y == 0 || x == width - 1 || y == height - 1
                guard isBorderPixel else { continue }

                clearConnectedBackground(
                    startX: x,
                    startY: y,
                    width: width,
                    height: height,
                    bytesPerRow: bytesPerRow,
                    pixels: pixels,
                    backgroundColor: backgroundColor,
                    backgroundLuminance: luminance(for: backgroundColor),
                    luminanceThreshold: luminanceThreshold,
                    threshold: colorDistanceThreshold
                )
            }
        }

        guard hasVisibleSubject(
            pixels: pixels,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow
        ), let output = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: output, scale: image.scale, orientation: .up)
    }

    private func averageBorderColor(
        pixels: UnsafeMutablePointer<UInt8>,
        width: Int,
        height: Int,
        bytesPerRow: Int
    ) -> (UInt8, UInt8, UInt8) {
        var red = 0
        var green = 0
        var blue = 0
        var count = 0

        let stepX = max(width / 20, 1)
        let stepY = max(height / 20, 1)

        for x in stride(from: 0, through: width - 1, by: stepX) {
            let top = rgb(atX: x, y: 0, pixels: pixels, bytesPerRow: bytesPerRow)
            let bottom = rgb(atX: x, y: height - 1, pixels: pixels, bytesPerRow: bytesPerRow)
            red += Int(top.0) + Int(bottom.0)
            green += Int(top.1) + Int(bottom.1)
            blue += Int(top.2) + Int(bottom.2)
            count += 2
        }

        for y in stride(from: 0, through: height - 1, by: stepY) {
            let left = rgb(atX: 0, y: y, pixels: pixels, bytesPerRow: bytesPerRow)
            let right = rgb(atX: width - 1, y: y, pixels: pixels, bytesPerRow: bytesPerRow)
            red += Int(left.0) + Int(right.0)
            green += Int(left.1) + Int(right.1)
            blue += Int(left.2) + Int(right.2)
            count += 2
        }

        guard count > 0 else { return (0, 0, 0) }
        return (UInt8(red / count), UInt8(green / count), UInt8(blue / count))
    }

    private func rgb(
        atX x: Int,
        y: Int,
        pixels: UnsafeMutablePointer<UInt8>,
        bytesPerRow: Int
    ) -> (UInt8, UInt8, UInt8) {
        let offset = (y * bytesPerRow) + (x * 4)
        return (pixels[offset], pixels[offset + 1], pixels[offset + 2])
    }

    private func clearConnectedBackground(
        startX: Int,
        startY: Int,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        pixels: UnsafeMutablePointer<UInt8>,
        backgroundColor: (UInt8, UInt8, UInt8),
        backgroundLuminance: Int,
        luminanceThreshold: Int,
        threshold: Int
    ) {
        var queue: [(Int, Int)] = [(startX, startY)]
        var visited = Set<Int>()

        while let (x, y) = queue.popLast() {
            let key = y * width + x
            if visited.contains(key) {
                continue
            }
            visited.insert(key)

            let offset = (y * bytesPerRow) + (x * 4)
            let alpha = pixels[offset + 3]
            if alpha == 0 || !isLikelyBackgroundPixel(
                offset: offset,
                pixels: pixels,
                backgroundColor: backgroundColor,
                backgroundLuminance: backgroundLuminance,
                luminanceThreshold: luminanceThreshold,
                colorDistanceThreshold: threshold
            ) {
                continue
            }

            pixels[offset + 3] = 0

            if x > 0 { queue.append((x - 1, y)) }
            if x < width - 1 { queue.append((x + 1, y)) }
            if y > 0 { queue.append((x, y - 1)) }
            if y < height - 1 { queue.append((x, y + 1)) }
        }
    }

    private func colorDistance(
        offset: Int,
        pixels: UnsafeMutablePointer<UInt8>,
        target: (UInt8, UInt8, UInt8)
    ) -> Int {
        let dr = Int(pixels[offset]) - Int(target.0)
        let dg = Int(pixels[offset + 1]) - Int(target.1)
        let db = Int(pixels[offset + 2]) - Int(target.2)
        return abs(dr) + abs(dg) + abs(db)
    }

    private func luminance(for color: (UInt8, UInt8, UInt8)) -> Int {
        (Int(color.0) * 299 + Int(color.1) * 587 + Int(color.2) * 114) / 1000
    }

    private func isLikelyBackgroundPixel(
        offset: Int,
        pixels: UnsafeMutablePointer<UInt8>,
        backgroundColor: (UInt8, UInt8, UInt8),
        backgroundLuminance: Int,
        luminanceThreshold: Int,
        colorDistanceThreshold: Int
    ) -> Bool {
        let pixelColor = (pixels[offset], pixels[offset + 1], pixels[offset + 2])
        let pixelLuminance = luminance(for: pixelColor)
        let luminanceDelta = abs(pixelLuminance - backgroundLuminance)
        let colorDelta = colorDistance(offset: offset, pixels: pixels, target: backgroundColor)

        return luminanceDelta <= luminanceThreshold && colorDelta <= colorDistanceThreshold
    }

    private func hasVisibleSubject(
        pixels: UnsafeMutablePointer<UInt8>,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        alphaThreshold: UInt8 = 8
    ) -> Bool {
        var opaqueCount = 0
        let minimumOpaquePixels = max((width * height) / 100, 2000)

        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[(y * bytesPerRow) + (x * 4) + 3]
                if alpha > alphaThreshold {
                    opaqueCount += 1
                    if opaqueCount >= minimumOpaquePixels {
                        return true
                    }
                }
            }
        }

        return false
    }
}

enum ClothingImageProcessorError: Error {
    case encodingFailed
}

private struct AlphaBoundsAnalysis {
    let transparentRatio: Double
    let opaqueBoundsAreaRatio: Double
}

private extension UIImage {
    func normalizedForVision() -> UIImage {
        if imageOrientation == .up, cgImage != nil {
            return self
        }

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1
        rendererFormat.opaque = false

        return UIGraphicsImageRenderer(size: size, format: rendererFormat).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func trimmedTransparentBounds(alphaThreshold: UInt8 = 8) -> UIImage {
        guard let cgImage else { return self }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return self
        }

        let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: drawRect)

        guard let data = context.data else { return self }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var foundOpaquePixel = false

        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[(y * bytesPerRow) + (x * bytesPerPixel) + 3]
                if alpha > alphaThreshold {
                    foundOpaquePixel = true
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard foundOpaquePixel else { return self }

        let padding = 12
        let cropX = max(minX - padding, 0)
        let cropY = max(minY - padding, 0)
        let cropWidth = min(maxX + padding + 1, width) - cropX
        let cropHeight = min(maxY + padding + 1, height) - cropY
        let cropRect = CGRect(
            x: cropX,
            y: cropY,
            width: cropWidth,
            height: cropHeight
        )

        guard let cropped = cgImage.cropping(to: cropRect.integral) else {
            return self
        }

        return UIImage(cgImage: cropped, scale: scale, orientation: .up)
    }

    func hasMeaningfulBackgroundRemoval(comparedTo original: UIImage, alphaThreshold: UInt8 = 8) -> Bool {
        guard
            let originalAnalysis = original.alphaBoundsAnalysis(alphaThreshold: alphaThreshold),
            let candidateAnalysis = alphaBoundsAnalysis(alphaThreshold: alphaThreshold)
        else {
            return false
        }

        let transparentRatioGain = candidateAnalysis.transparentRatio - originalAnalysis.transparentRatio
        let opaqueAreaReduction = originalAnalysis.opaqueBoundsAreaRatio - candidateAnalysis.opaqueBoundsAreaRatio

        return transparentRatioGain >= 0.02 || opaqueAreaReduction >= 0.06
    }

    func alphaBoundsAnalysis(alphaThreshold: UInt8 = 8) -> AlphaBoundsAnalysis? {
        guard let cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: drawRect)

        guard let data = context.data else { return nil }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        let totalPixels = width * height

        var transparentCount = 0
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var foundOpaquePixel = false

        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[(y * bytesPerRow) + (x * bytesPerPixel) + 3]
                if alpha > alphaThreshold {
                    foundOpaquePixel = true
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                } else {
                    transparentCount += 1
                }
            }
        }

        let transparentRatio = Double(transparentCount) / Double(max(totalPixels, 1))

        guard foundOpaquePixel else {
            return AlphaBoundsAnalysis(transparentRatio: transparentRatio, opaqueBoundsAreaRatio: 0)
        }

        let opaqueWidth = maxX - minX + 1
        let opaqueHeight = maxY - minY + 1
        let opaqueBoundsAreaRatio = Double(opaqueWidth * opaqueHeight) / Double(max(totalPixels, 1))

        return AlphaBoundsAnalysis(
            transparentRatio: transparentRatio,
            opaqueBoundsAreaRatio: opaqueBoundsAreaRatio
        )
    }

    private func averageBorderColor(
        pixels: UnsafeMutablePointer<UInt8>,
        width: Int,
        height: Int,
        bytesPerRow: Int
    ) -> (UInt8, UInt8, UInt8) {
        var red = 0
        var green = 0
        var blue = 0
        var count = 0

        let stepX = max(width / 20, 1)
        let stepY = max(height / 20, 1)

        for x in stride(from: 0, through: width - 1, by: stepX) {
            let top = rgb(atX: x, y: 0, pixels: pixels, bytesPerRow: bytesPerRow)
            let bottom = rgb(atX: x, y: height - 1, pixels: pixels, bytesPerRow: bytesPerRow)
            red += Int(top.0) + Int(bottom.0)
            green += Int(top.1) + Int(bottom.1)
            blue += Int(top.2) + Int(bottom.2)
            count += 2
        }

        for y in stride(from: 0, through: height - 1, by: stepY) {
            let left = rgb(atX: 0, y: y, pixels: pixels, bytesPerRow: bytesPerRow)
            let right = rgb(atX: width - 1, y: y, pixels: pixels, bytesPerRow: bytesPerRow)
            red += Int(left.0) + Int(right.0)
            green += Int(left.1) + Int(right.1)
            blue += Int(left.2) + Int(right.2)
            count += 2
        }

        guard count > 0 else { return (0, 0, 0) }
        return (UInt8(red / count), UInt8(green / count), UInt8(blue / count))
    }

    private func rgb(
        atX x: Int,
        y: Int,
        pixels: UnsafeMutablePointer<UInt8>,
        bytesPerRow: Int
    ) -> (UInt8, UInt8, UInt8) {
        let offset = (y * bytesPerRow) + (x * 4)
        return (pixels[offset], pixels[offset + 1], pixels[offset + 2])
    }

    private func clearConnectedBackground(
        startX: Int,
        startY: Int,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        pixels: UnsafeMutablePointer<UInt8>,
        backgroundColor: (UInt8, UInt8, UInt8),
        threshold: Int
    ) {
        var queue: [(Int, Int)] = [(startX, startY)]
        var visited = Set<Int>()

        while let (x, y) = queue.popLast() {
            let key = y * width + x
            if visited.contains(key) {
                continue
            }
            visited.insert(key)

            let offset = (y * bytesPerRow) + (x * 4)
            let alpha = pixels[offset + 3]
            if alpha == 0 || colorDistance(offset: offset, pixels: pixels, target: backgroundColor) > threshold {
                continue
            }

            pixels[offset + 3] = 0

            if x > 0 { queue.append((x - 1, y)) }
            if x < width - 1 { queue.append((x + 1, y)) }
            if y > 0 { queue.append((x, y - 1)) }
            if y < height - 1 { queue.append((x, y + 1)) }
        }
    }

    private func colorDistance(
        offset: Int,
        pixels: UnsafeMutablePointer<UInt8>,
        target: (UInt8, UInt8, UInt8)
    ) -> Int {
        let dr = Int(pixels[offset]) - Int(target.0)
        let dg = Int(pixels[offset + 1]) - Int(target.1)
        let db = Int(pixels[offset + 2]) - Int(target.2)
        return abs(dr) + abs(dg) + abs(db)
    }

    private func hasVisibleSubject(
        pixels: UnsafeMutablePointer<UInt8>,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        alphaThreshold: UInt8 = 8
    ) -> Bool {
        var opaqueCount = 0
        let minimumOpaquePixels = max((width * height) / 100, 2000)

        for y in 0..<height {
            for x in 0..<width {
                let alpha = pixels[(y * bytesPerRow) + (x * 4) + 3]
                if alpha > alphaThreshold {
                    opaqueCount += 1
                    if opaqueCount >= minimumOpaquePixels {
                        return true
                    }
                }
            }
        }

        return false
    }
}

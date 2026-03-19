import SwiftUI
import UIKit

extension Data {
    var uiImage: UIImage? {
        UIImage(data: self)
    }

    var swiftUIImage: Image? {
        guard let uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}

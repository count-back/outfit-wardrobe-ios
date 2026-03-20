import Foundation
import Observation

@Observable
final class AppContainer {
    var selectedTab: AppTab = .wardrobe
    var operationFeedback: OperationFeedback?
    var pendingOutfitReuse: OutfitReuseRequest?
    let imageProcessor = ClothingImageProcessor()
    let previewComposer = OutfitPreviewComposer()
    let scorer = OutfitScorer()

    @ObservationIgnored private var feedbackDismissTask: Task<Void, Never>?

    func showOperationFeedback(_ feedback: OperationFeedback, autoDismissAfter delayNanoseconds: UInt64 = 2_000_000_000) {
        feedbackDismissTask?.cancel()
        operationFeedback = feedback

        feedbackDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else { return }
            self?.operationFeedback = nil
        }
    }

    func hideOperationFeedback() {
        feedbackDismissTask?.cancel()
        operationFeedback = nil
    }
}

struct OutfitReuseRequest: Equatable {
    let itemIDs: [UUID]
}

enum AppTab: Hashable {
    case wardrobe
    case outfit
    case history
}

struct OperationFeedback: Equatable {
    enum Style {
        case success
        case error
    }

    var message: String
    var style: Style
}

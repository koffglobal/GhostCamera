import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    @Published var ghostEnabled: Bool = false
    @Published var ghostOpacity: Double = 0.45
    @Published var ghostBlur: Double = 0.0
    @Published var ghostScale: Double = 1.0
    @Published var ghostOffset: CGSize = .zero
    @Published var ghostImage: UIImage? = nil
    @Published var controlsVisible: Bool = true
    @Published var lastCapturedImage: UIImage? = nil
    @Published var showCapturedPreview: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false

    func resetGhostTransform() {
        ghostScale = 1.0
        ghostOffset = .zero
    }

    func flashError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

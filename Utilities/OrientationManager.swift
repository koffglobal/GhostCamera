import AVFoundation
import UIKit
import Combine

final class OrientationManager {
    static let shared = OrientationManager()

    @Published private(set) var currentInterfaceOrientation: UIInterfaceOrientation = .portrait

    var currentCaptureOrientation: AVCaptureVideoOrientation {
        switch currentInterfaceOrientation {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return .portrait
        }
    }

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification, object: nil
        )
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        updateFromDevice()
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    @objc private func orientationChanged() {
        updateFromDevice()
    }

    private func updateFromDevice() {
        let deviceOrientation = UIDevice.current.orientation
        let interfaceOrientation: UIInterfaceOrientation
        switch deviceOrientation {
        case .portrait: interfaceOrientation = .portrait
        case .portraitUpsideDown: interfaceOrientation = .portraitUpsideDown
        case .landscapeLeft: interfaceOrientation = .landscapeRight
        case .landscapeRight: interfaceOrientation = .landscapeLeft
        default: interfaceOrientation = .portrait
        }
        DispatchQueue.main.async { [weak self] in
            self?.currentInterfaceOrientation = interfaceOrientation
        }
    }
}

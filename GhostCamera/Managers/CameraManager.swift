import AVFoundation
import UIKit
import Combine

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didFailWithError error: CameraError)
    func cameraManagerDidStartRunning(_ manager: CameraManager)
}

enum CameraError: Error, LocalizedError {
    case permissionDenied
    case unavailable
    case initializationFailed
    case captureFailed
    case invalidDevice

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Camera access is required. Enable it in Settings."
        case .unavailable: return "No camera available on this device."
        case .initializationFailed: return "Failed to initialize the camera. Please restart the app."
        case .captureFailed: return "Photo capture failed. Please try again."
        case .invalidDevice: return "Could not select a valid camera device."
        }
    }
}

final class CameraManager: NSObject, ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var isConfigured = false

    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()

    weak var delegate: CameraManagerDelegate?

    private var videoDeviceInput: AVCaptureDeviceInput?
    private let sessionQueue = DispatchQueue(label: "com.ghostcamera.session")
    private var isConfiguredOnce = false

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleMemoryPressure),
            name: UIApplication.didReceiveMemoryWarningNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Configuration

    func configure() {
        guard PermissionsManager.shared.cameraStatus() == .granted else {
            delegate?.cameraManager(self, didFailWithError: .permissionDenied)
            return
        }
        sessionQueue.async { [weak self] in
            self?.setupSession()
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        do {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                ?? AVCaptureDevice.default(for: .video) else {
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.cameraManager(self, didFailWithError: .unavailable)
                }
                return
            }

            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                videoDeviceInput = input
            } else {
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.cameraManager(self, didFailWithError: .initializationFailed)
                }
                return
            }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.maxPhotoQualityPrioritization = .quality
            } else {
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.delegate?.cameraManager(self, didFailWithError: .initializationFailed)
                }
                return
            }

            session.commitConfiguration()

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.isConfigured = true
                self.start()
            }
        } catch {
            session.commitConfiguration()
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.cameraManager(self, didFailWithError: .initializationFailed)
            }
        }
    }

    // MARK: - Session Control

    func start() {
        guard isConfigured, !session.isRunning else { return }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isRunning = self.session.isRunning
                if self.session.isRunning {
                    self.delegate?.cameraManagerDidStartRunning(self)
                }
            }
        }
    }

    func stop() {
        guard session.isRunning else { return }
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { [weak self] in
                self?.isRunning = false
            }
        }
    }

    // MARK: - Orientation

    /// Call from the UI layer whenever the interface orientation changes.
    func updateOrientation(_ orientation: AVCaptureVideoOrientation) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if let connection = self.photoOutput.connection(with: .video),
               connection.isVideoOrientationSupported {
                connection.videoOrientation = orientation
            }
        }
    }

    // MARK: - Capture

    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        guard isConfigured, session.isRunning else {
            delegate?.cameraManager(self, didFailWithError: .captureFailed)
            return
        }
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings.format = [AVVideoCodecKey: AVVideoCodecType.hevc]
        }
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if let connection = self.photoOutput.connection(with: .video),
               connection.isVideoOrientationSupported {
                connection.videoOrientation = OrientationManager.shared.currentCaptureOrientation
            }
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    // MARK: - Notifications

    @objc private func handleMemoryPressure() {
        // Session keeps running; iOS purges caches. Nothing destructive needed.
    }

    @objc private func handleBackground() {
        stop()
    }

    @objc private func handleForeground() {
        start()
    }
}

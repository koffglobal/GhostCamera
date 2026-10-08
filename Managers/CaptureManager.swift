import AVFoundation
import Photos
import UIKit

protocol CaptureManagerDelegate: AnyObject {
    func captureManager(_ manager: CaptureManager, didCapture image: UIImage)
    func captureManager(_ manager: CaptureManager, didFailWith error: CameraError)
}

final class CaptureManager: NSObject, AVCapturePhotoCaptureDelegate {
    weak var delegate: CaptureManagerDelegate?

    private let processingQueue = DispatchQueue(label: "com.ghostcamera.capture")

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.captureManager(self!, didFailWith: .captureFailed)
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.captureManager(self!, didFailWith: .captureFailed)
            }
            return
        }

        // AVCapturePhotoOutput already applies correct EXIF orientation
        // because we set connection.videoOrientation before capture.
        // Normalize to .up so downstream display is consistent.
        let normalized = image.normalizedOrientation()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.captureManager(self, didCapture: normalized)
            self.saveToPhotoLibrary(normalized)
        }
    }

    private func saveToPhotoLibrary(_ image: UIImage) {
        guard PermissionsManager.shared.photoStatus() == .granted else { return }

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: image.jpegData(compressionQuality: 0.95) ?? Data(), options: nil)
        }, completionHandler: { _, _ in })
    }
}

extension UIImage {
    /// Returns an image with orientation forced to .up, redrawing if needed.
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return normalized
    }
}

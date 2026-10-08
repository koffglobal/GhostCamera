# Ghost Camera — iOS App

A polished iPhone camera app with a "Ghost Mode" overlay for reference-photo alignment.

## Project Structure

```
GhostCamera/
├── GhostCamera.xcodeproj/          (created via Xcode)
├── GhostCamera/
│   ├── GhostCameraApp.swift          App entry point
│   ├── Info.plist                    Permissions & orientation config
│   ├── Models/
│   │   └── AppSettings.swift         Observable app state
│   ├── Managers/
│   │   ├── CameraManager.swift       AVFoundation session, capture, orientation
│   │   ├── CaptureManager.swift      Photo capture delegate + save to Photos
│   │   └── PermissionsManager.swift  Camera/Photo permission handling
│   ├── Views/
│   │   ├── ContentView.swift         Root view, shutter, controls orchestration
│   │   ├── CameraPreviewView.swift   AVCaptureVideoPreviewLayer wrapper
│   │   ├── GhostOverlayView.swift    Draggable/zoomable ghost image
│   │   ├── GhostControlPanel.swift   Glass control panel (opacity/blur/reset)
│   │   ├── PhotoPicker.swift         PHPickerViewController wrapper
│   │   ├── PermissionView.swift      Glass-style permission explanation
│   │   └── CapturedPreviewView.swift Post-capture preview
│   └── Utilities/
│       └── OrientationManager.swift  Device orientation → capture orientation
└── README.md
```

## Architecture

- **CameraManager** — owns `AVCaptureSession`, device input, `AVCapturePhotoOutput`. Runs all session work on a dedicated serial queue. Handles background/foreground/memory-pressure notifications.
- **CaptureManager** — `AVCapturePhotoCaptureDelegate`. Receives the captured photo, normalizes orientation, saves to `PHPhotoLibrary`.
- **OrientationManager** — observes `UIDevice.orientationDidChangeNotification`, maps to `AVCaptureVideoOrientation`, shared singleton.
- **CameraPreviewView** — `UIViewRepresentable` wrapping `AVCaptureVideoPreviewLayer` with `.resizeAspectFill` gravity. Orientation updated via `updateUIView` on rotation.
- **GhostOverlayView** — `Image` with `.aspectRatio(.fill)` matching the preview layer gravity, so the ghost and camera FOV stay aligned under rotation. Drag + pinch gestures, opacity/blur from settings.
- **GhostControlPanel** — `.ultraThinMaterial` glass panel, auto-hides after 4s or on tap.

## Orientation Correctness

1. `CameraPreviewView.updateUIView` sets `videoPreviewLayer.connection.videoOrientation` from `OrientationManager` on every SwiftUI update (triggered by rotation).
2. Before each capture, `CameraManager.capturePhoto` sets `photoOutput.connection.videoOrientation` to the current orientation — `AVCapturePhotoOutput` writes correct EXIF.
3. `CaptureManager` normalizes the captured `UIImage` to `.up` so display is always correct.
4. Ghost overlay uses `.resizeAspectFill` in the same view bounds as the preview layer → alignment preserved across rotations.

## Build Instructions (Windows → macOS/Xcode)

### What you can do on Windows
- Edit all Swift source files (any editor).
- Review architecture, logic, and UI code.

### What requires macOS/Xcode
- Compiling, signing, and installing on a physical iPhone requires Xcode on macOS (or a macOS VM/cloud Mac).

### Steps

1. **On macOS**, install Xcode from the App Store.
2. Open Terminal, run:
   ```bash
   cd /path/to/GhostCamera
   ```
3. Create the Xcode project:
   - Open Xcode → File → New → Project → iOS → App
   - Name: `GhostCamera`, Interface: SwiftUI, Language: Swift
   - Save into the `GhostCamera/` folder
4. Replace the auto-generated `GhostCameraApp.swift` and `ContentView.swift` with the files from this repo. Add all other files/folders (Models, Managers, Views, Utilities, Info.plist) via "Add Files to GhostCamera".
5. In project settings → Signing & Capabilities, select your Apple ID team.
6. Connect your iPhone via USB, select it as the target, press **Run** (⌘R).
7. On the iPhone, trust the developer certificate: Settings → General → VPN & Device Management.

### Alternative: Cloud Mac
- Services like MacStadium, MacinCloud, or GitHub Actions macOS runners can build the app if you don't own a Mac.

## Permissions

- **Camera** — requested on first launch. If denied, a glass-style screen explains and offers an "Open Settings" button.
- **Photo Library (Add Only)** — requested on first save. Same denial flow.

## Error Handling

| Scenario | Behavior |
|---|---|
| Camera unavailable | Alert + permission screen |
| Camera denied | Glass screen → Settings button |
| Photo denied | Capture still works; save skipped silently |
| Invalid image | Picker returns nothing; no crash |
| Init failure | Alert with restart suggestion |
| Rotation | OrientationManager updates preview + capture |
| Background/Foreground | Session stops/starts automatically |
| Memory pressure | Non-destructive; iOS handles cleanup |
| Capture failure | Alert, user can retry |

## Performance

- Session work on dedicated serial queue (never blocks UI).
- Blur uses SwiftUI's `.blur(radius:)` which is GPU-accelerated by the compositor.
- No per-frame processing — preview layer renders directly.
- Ghost overlay is a single `Image` view; no offscreen rendering unless blur > 0.

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var captureManager = CaptureManager()

    @State private var showPhotoPicker = false
    @State private var hasCheckedPermissions = false
    @State private var cameraGranted = false
    @State private var controlsTimer: Timer?

    var body: some View {
        ZStack {
            if cameraGranted {
                cameraView
            } else {
                PermissionView(
                    title: "Camera Access Needed",
                    message: "Ghost Camera needs access to your camera to show the live preview and capture photos. Your photos stay on your device.",
                    onOpenSettings: { PermissionsManager.shared.openSettings() }
                )
            }

            if settings.showCapturedPreview, let image = settings.lastCapturedImage {
                CapturedPreviewView(
                    image: image,
                    onDismiss: { settings.showCapturedPreview = false },
                    onRetake: { settings.showCapturedPreview = false }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: settings.showCapturedPreview)
        .alert("Error", isPresented: $settings.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(settings.errorMessage ?? "An unknown error occurred.")
        }
        .onAppear {
            checkPermissions()
            cameraManager.delegate = self
            captureManager.delegate = self
            cameraManager.configure()
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker { image in
                settings.ghostImage = image
                settings.ghostEnabled = true
                settings.resetGhostTransform()
            }
        }
    }

    private var cameraView: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()

                if settings.ghostEnabled {
                    GhostOverlayView(
                        onTap: { toggleControls() }
                    )
                    .ignoresSafeArea()
                }

                VStack {
                    Spacer()
                    if settings.controlsVisible && settings.ghostEnabled {
                        GhostControlPanel(
                            onPickPhoto: { showPhotoPicker = true },
                            onReset: { settings.resetGhostTransform() }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    shutterBar
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { toggleControls() }
        }
    }

    private var shutterBar: some View {
        HStack {
            Button(action: { settings.ghostEnabled.toggle() }) {
                Image(systemName: settings.ghostEnabled ? "eye.fill" : "eye")
                    .font(.title2)
                    .foregroundColor(settings.ghostEnabled ? .cyan : .white)
                    .padding(14)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            Button(action: capture) {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 58, height: 58)
                    )
            }

            Spacer()

            Button(action: { showPhotoPicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 30)
    }

    private func checkPermissions() {
        cameraGranted = PermissionsManager.shared.cameraStatus() == .granted
        if !cameraGranted {
            PermissionsManager.shared.requestCamera { granted in
                cameraGranted = granted
            }
        }
    }

    private func capture() {
        cameraManager.capturePhoto(delegate: captureManager)
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.25)) {
            settings.controlsVisible.toggle()
        }
        scheduleControlsAutoHide()
    }

    private func scheduleControlsAutoHide() {
        controlsTimer?.invalidate()
        guard settings.controlsVisible else { return }
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.25)) {
                    settings.controlsVisible = false
                }
            }
        }
    }
}

extension ContentView: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didFailWithError error: CameraError) {
        settings.flashError(error.localizedDescription)
    }

    func cameraManagerDidStartRunning(_ manager: CameraManager) {
        manager.updateOrientation(OrientationManager.shared.currentCaptureOrientation)
    }
}

extension ContentView: CaptureManagerDelegate {
    func captureManager(_ manager: CaptureManager, didCapture image: UIImage) {
        settings.lastCapturedImage = image
        settings.showCapturedPreview = true
    }

    func captureManager(_ manager: CaptureManager, didFailWith error: CameraError) {
        settings.flashError(error.localizedDescription)
    }
}

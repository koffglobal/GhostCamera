import SwiftUI

@main
struct GhostCameraApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(.dark)
        }
    }
}

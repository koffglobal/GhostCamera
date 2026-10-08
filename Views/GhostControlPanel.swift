import SwiftUI

struct GhostControlPanel: View {
    @EnvironmentObject var settings: AppSettings
    let onPickPhoto: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Ghost Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $settings.ghostEnabled)
                    .labelsHidden()
                    .tint(.cyan)
            }

            HStack {
                Text("Opacity")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 60, alignment: .leading)
                Slider(value: $settings.ghostOpacity, in: 0.05...1.0)
                    .tint(.cyan)
            }

            HStack {
                Text("Blur")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 60, alignment: .leading)
                Slider(value: $settings.ghostBlur, in: 0...20)
                    .tint(.cyan)
            }

            HStack(spacing: 16) {
                Button(action: onPickPhoto) {
                    Label("Photo", systemImage: "photo.on.rectangle")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundColor(.white)
                }

                Button(action: onReset) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }
}

import SwiftUI

struct GhostOverlayView: View {
    @EnvironmentObject var settings: AppSettings
    let onTap: () -> Void

    @State private var baseOffset: CGSize = .zero

    var body: some View {
        GeometryReader { _ in
            if let image = settings.ghostImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(settings.ghostOpacity)
                    .blur(radius: settings.ghostBlur)
                    .scaleEffect(settings.ghostScale)
                    .offset(settings.ghostOffset)
                    .gesture(dragGesture)
                    .simultaneousGesture(magnifyGesture)
                    .onTapGesture { onTap() }
            }
        }
        .clipped()
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                settings.ghostOffset = CGSize(
                    width: baseOffset.width + value.translation.width,
                    height: baseOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                baseOffset = settings.ghostOffset
            }
    }

    private var magnifyGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                settings.ghostScale = max(0.3, min(5.0, scale))
            }
    }
}

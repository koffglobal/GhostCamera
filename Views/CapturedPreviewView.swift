import SwiftUI

struct CapturedPreviewView: View {
    let image: UIImage
    let onDismiss: () -> Void
    let onRetake: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                HStack(spacing: 40) {
                    Button(action: onRetake) {
                        Text("Retake")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

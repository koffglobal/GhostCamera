import SwiftUI

struct PermissionView: View {
    let title: String
    let message: String
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.cyan)

            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(.white, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

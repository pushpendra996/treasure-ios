import SwiftUI

struct OfflineBanner: View {
    @ObservedObject private var monitor = NetworkMonitor.shared

    var body: some View {
        if !monitor.isConnected {
            Text("You're offline. Changes will sync when you're back.")
                .font(.footnote)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.red.opacity(0.85))
        }
    }
}

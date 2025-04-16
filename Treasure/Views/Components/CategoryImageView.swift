import SwiftUI
import FirebaseStorage
import Network

struct CategoryImageView: View {
    let imageUrl: String
    let size: CGFloat
    
    @State private var downloadURL: URL?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var isConnected = true
    @State private var imageLoadAttempts = 0
    private let maxAttempts = 3
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    var body: some View {
        Group {
            if !isConnected {
                Image(systemName: "wifi.slash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: size, height: size)
            } else if let downloadURL = downloadURL {
                AsyncImage(url: downloadURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure(_):
                        if imageLoadAttempts < maxAttempts {
                            ProgressView()
                                .frame(width: size, height: size)
                                .task {
                                    imageLoadAttempts += 1
                                    try? await Task.sleep(nanoseconds: UInt64(2 * imageLoadAttempts) * 1_000_000_000)
                                    await loadImage()
                                }
                        } else {
                            Image(systemName: "photo.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.gray)
                                .frame(width: size, height: size)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                ProgressView()
                    .frame(width: size, height: size)
            }
        }
        .clipShape(Circle())
        .background(
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: size + 8, height: size + 8)
        )
        .task {
            print("Starting to load image from path: \(imageUrl)")
            setupNetworkMonitoring()
            await loadImage()
        }
        .onDisappear {
            monitor.cancel()
        }
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let oldStatus = self.isConnected
                self.isConnected = path.status == .satisfied
                print("Network status changed: \(oldStatus) -> \(self.isConnected)")
                if self.isConnected && self.downloadURL == nil {
                    Task {
                        await loadImage()
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func loadImage() async {
        guard downloadURL == nil else { return }
        guard isConnected else {
            print("No network connection available")
            return
        }
        
        do {
            print("Attempting to load image from Firebase Storage: \(imageUrl)")
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let imageRef = storageRef.child(imageUrl)
            
            print("Getting download URL for: \(imageUrl)")
            let url = try await imageRef.downloadURL()
            print("Successfully got download URL: \(url.absoluteString)")
            
            await MainActor.run {
                self.downloadURL = url
                self.isLoading = false
            }
        } catch let downloadError {
            print("Error loading image from path \(imageUrl)")
            print("Error loading image: \(downloadError.localizedDescription)")
            if let nsError = downloadError as NSError? {
                print("Error domain: \(nsError.domain)")
                print("Error code: \(nsError.code)")
                print("Error user info: \(nsError.userInfo)")
            }
            
            if imageLoadAttempts < maxAttempts {
                imageLoadAttempts += 1
                let delaySeconds = UInt64(2 * imageLoadAttempts) * 1_000_000_000
                try? await Task.sleep(nanoseconds: delaySeconds)
                await loadImage()
            }
            
            await MainActor.run {
                self.error = downloadError
                self.isLoading = false
            }
        }
    }
} 

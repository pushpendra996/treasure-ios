import SwiftUI

struct CategoryImageView: View {
    let imageUrl: String
    let size: CGFloat

    @State private var image: UIImage?
    @State private var triedNetwork = false

    var body: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.12))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(6)
            } else if triedNetwork {
                Image(systemName: "photo.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: imageUrl) {
            if imageUrl.isEmpty { return }
            if let cached = CategoryIconStore.cachedImage(path: imageUrl) {
                image = cached
                return
            }
            image = await CategoryIconStore.load(path: imageUrl)
            triedNetwork = image == nil
        }
    }
}

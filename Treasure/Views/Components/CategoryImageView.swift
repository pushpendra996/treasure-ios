import SwiftUI

struct CategoryImageView: View {
    let imageUrl: String
    let size: CGFloat
    var name: String = ""

    @State private var image: UIImage?
    @State private var triedNetwork = false

    var body: some View {
        ZStack {
            Circle().fill(letterColor.opacity(imageUrl.isEmpty && !name.isEmpty ? 1 : 0.12))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(6)
            } else if imageUrl.isEmpty, let letter = name.trimmingCharacters(in: .whitespacesAndNewlines).first {
                Text(String(letter).uppercased())
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(.white)
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
            image = nil
            triedNetwork = false
            if imageUrl.isEmpty { return }
            if let cached = CategoryIconStore.cachedImage(path: imageUrl) {
                image = cached
                return
            }
            image = await CategoryIconStore.load(path: imageUrl)
            triedNetwork = image == nil
        }
    }

    private var letterColor: Color {
        let palette: [Color] = [
            Color(red: 0.36, green: 0.55, blue: 0.94),
            Color(red: 0.49, green: 0.36, blue: 0.75),
            Color(red: 0.88, green: 0.48, blue: 0.37),
            Color(red: 0.24, green: 0.60, blue: 0.47),
            Color(red: 0.83, green: 0.63, blue: 0.09),
            Color(red: 0.77, green: 0.27, blue: 0.41)
        ]
        let idx = abs(name.lowercased().hashValue) % palette.count
        return palette[idx]
    }
}

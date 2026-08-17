import Foundation
import UIKit
import FirebaseStorage

enum CategoryIconStore {
    private static let memory = NSCache<NSString, UIImage>()

    static func cachedImage(path: String) -> UIImage? {
        if let memoryHit = memory.object(forKey: path as NSString) {
            return memoryHit
        }
        let url = localURL(for: path)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        memory.setObject(image, forKey: path as NSString)
        return image
    }

    static func load(path: String) async -> UIImage? {
        if let cached = cachedImage(path: path) {
            return cached
        }
        do {
            let data = try await Storage.storage().reference().child(path).data(maxSize: 2 * 1024 * 1024)
            let url = localURL(for: path)
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: url, options: .atomic)
            let image = UIImage(data: data)
            if let image {
                memory.setObject(image, forKey: path as NSString)
            }
            return image
        } catch {
            return cachedImage(path: path)
        }
    }

    static func prefetch(paths: [String]) {
        Task.detached(priority: .utility) {
            for path in paths where !path.isEmpty {
                _ = await load(path: path)
            }
        }
    }

    private static func localURL(for path: String) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("category_icons", isDirectory: true)
        let name = path.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "..", with: "_")
        return dir.appendingPathComponent(name)
    }
}

//
//  AvatarCache.swift
//  stat-tracker
//

import UIKit

@MainActor
final class AvatarCache {
    static let shared = AvatarCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
    }

    func image(for username: String) async -> UIImage? {
        if let hit = cache.object(forKey: username as NSString) { return hit }
        guard let fetched = await fetch(username: username) else { return nil }
        cache.setObject(fetched, forKey: username as NSString)
        return fetched
    }

    /// Call after a successful upload so the next load hits the network.
    func invalidate(username: String) {
        cache.removeObject(forKey: username as NSString)
    }

    private func fetch(username: String) async -> UIImage? {
        let path = String(format: Constants.API.User.getAvatar, username)
        guard let url = URL(string: Constants.API.URL + path) else { return nil }
        guard let (data, response) = try? await URLSession.shared.data(from: url) else { return nil }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return UIImage(data: data)
    }
}

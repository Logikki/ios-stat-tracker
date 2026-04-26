//
//  UserAvatarView.swift
//  stat-tracker
//

import SwiftUI

/// Circular avatar that loads from the API with an initials fallback.
/// Pass `preloadedData` to skip the network fetch (e.g. when the image was
/// already embedded in an API response).
struct UserAvatarView: View {
    let username: String
    let initials: String
    let size: CGFloat
    var preloadedData: Data? = nil

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.15))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: size, height: size)
            } else {
                Text(initials)
                    .font(.system(size: size * 0.35).bold())
                    .foregroundColor(.blue)
            }
        }
        .frame(width: size, height: size)
        .task(id: username) {
            if let data = preloadedData, let loaded = UIImage(data: data) {
                image = loaded
            } else {
                image = await AvatarCache.shared.image(for: username)
            }
        }
    }
}

#if DEBUG
    #Preview {
        HStack(spacing: 16) {
            UserAvatarView(username: "alice", initials: "AS", size: 64)
            UserAvatarView(username: "bob", initials: "B", size: 44)
            UserAvatarView(username: "carol", initials: "C", size: 32)
        }
        .padding()
    }
#endif

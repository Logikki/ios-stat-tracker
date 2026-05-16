//
//  ChatBubbleView.swift
//  stat-tracker
//

import SwiftUI

struct ChatBubbleView: View {
    let message: DecryptedChatMessage
    let currentUsername: String?

    private var isOwn: Bool {
        message.message.sender.username == currentUsername
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isOwn { Spacer(minLength: 52) }
            VStack(alignment: isOwn ? .trailing : .leading, spacing: 3) {
                if !isOwn {
                    Text("@\(message.message.sender.username)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(message.plaintext ?? "🔒 Encrypted")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isOwn ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(isOwn ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(message.message.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !isOwn { Spacer(minLength: 52) }
        }
        .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

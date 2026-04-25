//
//  EmptyStateView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import SwiftUI

/// Lightweight empty-state placeholder used inside lists/forms and full-screen.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String?
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.bold())
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

/// Smaller inline variant suitable inside a Form/List section row.
struct InlineEmptyState: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}

#if DEBUG
    #Preview("Empty – with action") {
        EmptyStateView(
            icon: "person.3.sequence",
            title: "No leagues yet",
            message: "Create one or join with an invite code.",
            actionTitle: "Create league",
            action: {}
        )
    }

    #Preview("Empty – simple") {
        EmptyStateView(
            icon: "sportscourt",
            title: "No games yet",
            message: "Tap the Add tab to record your first match."
        )
    }

    #Preview("Inline empty") {
        Form {
            Section("Friends") {
                InlineEmptyState(icon: "person.2.slash", text: "You don't have any friends yet.")
            }
        }
    }
#endif

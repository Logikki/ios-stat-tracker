//
//  ProfileView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        Group {
            if let user = viewModel.user {
                Form {
                    headerSection(user: user)
                    statsSection
                    visibilitySection(user: user)
                    friendRequestsSection(user: user)
                    friendsSection(user: user)
                    addFriendSection
                }
            } else {
                ProgressView("Loading profile…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Profile")
        .refreshable { await viewModel.refresh() }
        .alert(
            "Notice",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func headerSection(user: User) -> some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.15))
                    Text(initials(for: user.name))
                        .font(.title.bold())
                        .foregroundColor(.blue)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name).font(.title3.bold())
                    Text("@\(user.username)").foregroundColor(.secondary)
                    Text(user.email).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private var statsSection: some View {
        Section("Stats") {
            HStack {
                StatTile(label: "Played", value: "\(viewModel.stats.played)")
                StatTile(label: "Wins", value: "\(viewModel.stats.wins)", color: .green)
                StatTile(label: "Draws", value: "\(viewModel.stats.draws)", color: .gray)
                StatTile(label: "Losses", value: "\(viewModel.stats.losses)", color: .red)
            }
            HStack {
                LabeledContent("Goals for", value: "\(viewModel.stats.goalsFor)")
                Spacer()
                LabeledContent("Goals against", value: "\(viewModel.stats.goalsAgainst)")
            }
            LabeledContent(
                "Win rate",
                value: viewModel.stats.winRate.formatted(.percent.precision(.fractionLength(0)))
            )
        }
    }

    private func visibilitySection(user: User) -> some View {
        Section("Privacy") {
            Picker("Profile visibility", selection: Binding(
                get: { user.profileVisibility },
                set: { viewModel.updateVisibility($0) }
            )) {
                ForEach(ProfileVisibility.allCases) { v in
                    Text(v.displayName).tag(v)
                }
            }
        }
    }

    @ViewBuilder
    private func friendRequestsSection(user: User) -> some View {
        if !user.friendRequests.isEmpty {
            Section("Friend requests") {
                ForEach(user.friendRequests) { req in
                    HStack {
                        Text("@\(req.username)")
                        Spacer()
                        Button("Accept") { viewModel.accept(req.username) }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        Button(role: .destructive) {
                            viewModel.reject(req.username)
                        } label: {
                            Text("Reject")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    private func friendsSection(user: User) -> some View {
        Section("Friends (\(user.friends.count))") {
            if user.friends.isEmpty {
                InlineEmptyState(
                    icon: "person.2.slash",
                    text: "You don't have any friends yet. Send a request below to get started."
                )
            } else {
                ForEach(user.friends) { friend in
                    HStack {
                        Text("@\(friend.username)")
                        Spacer()
                        Button(role: .destructive) {
                            viewModel.remove(friend.username)
                        } label: {
                            Image(systemName: "person.fill.xmark")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    private var addFriendSection: some View {
        Section("Add friend") {
            HStack {
                TextField("Username", text: $viewModel.addFriendUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Send") { viewModel.sendFriendRequest() }
                    .disabled(viewModel.isWorking || viewModel.addFriendUsername.isEmpty)
            }
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first }
        return String(chars).uppercased()
    }
}

private struct StatTile: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold().monospacedDigit()).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
    #Preview("Profile – populated") {
        NavigationStack {
            ProfileView(viewModel: ProfileViewModel.preview(profile: PreviewSamples.userWithEverything))
        }
    }

    #Preview("Profile – empty") {
        NavigationStack {
            ProfileView(viewModel: ProfileViewModel.preview(profile: PreviewSamples.userEmpty))
        }
    }

    #Preview("Profile – loading") {
        NavigationStack {
            ProfileView(viewModel: ProfileViewModel.preview(profile: nil))
        }
    }
#endif

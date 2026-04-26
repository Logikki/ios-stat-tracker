//
//  OtherProfileView.swift
//  stat-tracker
//

import SwiftUI

struct OtherProfileView: View {
    @ObservedObject var viewModel: OtherProfileViewModel
    @EnvironmentObject var dependencies: DependencyContainer

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile = viewModel.profile {
                if profile.visible {
                    fullView(profile: profile)
                } else {
                    limitedView(username: profile.username, reason: profile.reason)
                }
            } else if viewModel.errorMessage != nil {
                ContentUnavailableView("Couldn't load profile", systemImage: "person.slash")
            }
        }
        .navigationTitle("@\(viewModel.username)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: LightUser.self) { user in
            OtherProfileView(viewModel: dependencies.createOtherProfileViewModel(username: user.username))
        }
        .task { await viewModel.load() }
        .alert(
            "Error",
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

    // MARK: - Full View

    private func fullView(profile: OtherUserProfile) -> some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.blue.opacity(0.15))
                        Text(initials(for: profile.name ?? profile.username))
                            .font(.title.bold())
                            .foregroundColor(.blue)
                    }
                    .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 2) {
                        if let name = profile.name {
                            Text(name).font(.title3.bold())
                        }
                        Text("@\(profile.username)").foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }

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

            if let leagues = profile.leagues, !leagues.isEmpty {
                Section("Leagues (\(leagues.count))") {
                    ForEach(leagues) { league in
                        Text(league.name)
                    }
                }
            }

            if let friends = profile.friends {
                Section("Friends (\(friends.count))") {
                    if friends.isEmpty {
                        InlineEmptyState(icon: "person.2.slash", text: "No friends yet.")
                    } else {
                        ForEach(friends) { friend in
                            NavigationLink(value: friend) {
                                Text("@\(friend.username)")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Limited View

    private func limitedView(username: String, reason: LimitedAccessReason?) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(Color.secondary.opacity(0.12))
                Image(systemName: reason == .private ? "lock.fill" : "person.fill.questionmark")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)

            VStack(spacing: 6) {
                Text("@\(username)").font(.title3.bold())
                Text(reasonText(for: reason))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if reason == .notFriends {
                Button {
                    viewModel.sendFriendRequest()
                } label: {
                    Label("Send Friend Request", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reasonText(for reason: LimitedAccessReason?) -> String {
        switch reason {
        case .private: return "This profile is private."
        case .notFriends: return "Add this user as a friend to see their full profile."
        case nil: return "This profile is not visible."
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        return String(parts.prefix(2).compactMap(\.first)).uppercased()
    }
}

#if DEBUG
    #Preview("Full profile") {
        NavigationStack {
            OtherProfileView(viewModel: OtherProfileViewModel.previewFull())
                .environmentObject(DependencyContainer.shared)
        }
    }

    #Preview("Private profile") {
        NavigationStack {
            OtherProfileView(viewModel: OtherProfileViewModel.previewPrivate())
                .environmentObject(DependencyContainer.shared)
        }
    }

    #Preview("Not friends") {
        NavigationStack {
            OtherProfileView(viewModel: OtherProfileViewModel.previewNotFriends())
                .environmentObject(DependencyContainer.shared)
        }
    }
#endif

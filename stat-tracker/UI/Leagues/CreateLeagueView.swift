//
//  CreateLeagueView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import SwiftUI

struct CreateLeagueView: View {
    @ObservedObject var viewModel: CreateLeagueViewModel
    var onDone: () -> Void

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $viewModel.name)
                TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                    .lineLimit(2...4)
                DatePicker("Ends on", selection: $viewModel.duration, displayedComponents: .date)
            }

            Section("Game types") {
                ForEach(GameType.allCases) { type in
                    Toggle(isOn: Binding(
                        get: { viewModel.gameTypes.contains(type) },
                        set: { _ in viewModel.toggle(type) }
                    )) {
                        Label(type.displayName, systemImage: type.systemImage)
                    }
                }
            }

            Section {
                TextField("Comma-separated usernames", text: $viewModel.extraUsernames, axis: .vertical)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Members (optional)")
            } footer: {
                Text("You will be added automatically. Only users that already exist will be included.")
            }

            if let error = viewModel.errorMessage {
                Section { Text(error).foregroundColor(.red) }
            }

            Section {
                Button {
                    viewModel.submit(onSuccess: onDone)
                } label: {
                    HStack {
                        if viewModel.isSubmitting { ProgressView() }
                        Text("Create league")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.canSubmit)
            }
        }
        .navigationTitle("New league")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onDone)
            }
        }
    }
}

#if DEBUG
#Preview("Create league") {
    NavigationStack {
        CreateLeagueView(viewModel: CreateLeagueViewModel.preview(), onDone: {})
    }
}
#endif

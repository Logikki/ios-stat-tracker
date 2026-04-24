//
//  JoinLeagueView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import SwiftUI

struct JoinLeagueView: View {
    @ObservedObject var viewModel: JoinLeagueViewModel
    var onDone: () -> Void

    var body: some View {
        Form {
            Section("Invitation code") {
                TextField("Paste your code", text: $viewModel.code)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
                        Text("Join league")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.canSubmit)
            }
        }
        .navigationTitle("Join league")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onDone)
            }
        }
    }
}

#if DEBUG
#Preview("Join league") {
    NavigationStack {
        JoinLeagueView(viewModel: JoinLeagueViewModel.preview(), onDone: {})
    }
}
#endif

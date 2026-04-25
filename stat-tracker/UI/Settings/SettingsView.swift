//
//  SettingsView.swift
//  stat-tracker
//
//  Created by Rkos on 29.1.2025.
//

import SwiftUI

struct SettingsView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @ObservedObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $viewModel.isDarkMode)
                }

                Section {
                    Picker("BackendChoice", selection: environmentBinding) {
                        Text("Production").tag(BackendChoice.production)
                        Text("Local (simulator)").tag(BackendChoice.local)
                        Text("Custom").tag(BackendChoice.custom)
                    }
                    .pickerStyle(.segmented)

                    if environmentBinding.wrappedValue == .custom {
                        TextField("https://example.com", text: $viewModel.backendURLDraft)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        Button("Apply custom URL") { viewModel.applyDraft() }
                            .disabled(viewModel.backendURLDraft == viewModel.activeBackendURL)
                    }

                    LabeledContent("Active") {
                        Text(viewModel.activeBackendURL)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }

                    Button("Reset to default", role: .destructive) {
                        viewModel.resetToDefault()
                    }
                    .disabled(viewModel.isUsingProduction)
                } header: {
                    Text("Backend")
                } footer: {
                    Text("Switching backends signs you out so an old token doesn't leak across environments. Local works from the iOS Simulator on your Mac. On a physical device, set a custom URL like http://192.168.x.x:3000.")
                }

                Section("Account") {
                    Button("Logout") { viewModel.logout() }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private enum BackendChoice: Hashable { case production, local, custom }

    private var environmentBinding: Binding<BackendChoice> {
        Binding(
            get: {
                if viewModel.isUsingProduction { return .production }
                if viewModel.isUsingLocal { return .local }
                return .custom
            },
            set: { newValue in
                switch newValue {
                case .production: viewModel.useProduction()
                case .local: viewModel.useLocal()
                case .custom:
                    // Stay on whatever URL is active; user will edit the field next.
                    break
                }
            }
        )
    }
}

#if DEBUG
    #Preview("Settings") {
        SettingsView(viewModel: SettingsViewModel(authenticationManager: AuthenticationManagerImpl.shared))
    }
#endif

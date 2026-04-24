//
//  AuthView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 17.5.2025.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    VStack(spacing: 12) {
                        TextField("Username", text: $viewModel.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)

                        if viewModel.mode == .signUp {
                            TextField("Display name", text: $viewModel.name)
                                .textFieldStyle(.roundedBorder)

                            TextField("Email", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textFieldStyle(.roundedBorder)
                        }

                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)

                        if viewModel.mode == .signUp {
                            Picker("Profile visibility", selection: $viewModel.visibility) {
                                ForEach(ProfileVisibility.allCases) { v in
                                    Text(v.displayName).tag(v)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if viewModel.overallLoading {
                        ProgressView()
                            .padding()
                    } else {
                        Button(action: viewModel.submit) {
                            Text(viewModel.mode == .login ? "Log in" : "Create account")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isSubmitDisabled)
                        .padding(.horizontal)
                    }

                    Button(action: viewModel.toggleMode) {
                        Text(viewModel.mode == .login
                             ? "Don't have an account? Sign up"
                             : "Already have an account? Log in")
                            .font(.footnote)
                    }
                }
                .padding(.vertical, 32)
            }
            .navigationTitle(viewModel.mode == .login ? "Welcome back" : "Create account")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
            Text("Stat Tracker")
                .font(.largeTitle.bold())
            Text("Track your sports games with friends")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#if DEBUG
#Preview("Login") {
    let auth = AuthenticationManagerImpl.shared
    let user = UserManagerImpl(authenticationManager: auth)
    let vm = AuthViewModel(authenticationManager: auth, userManager: user)
    return AuthView(viewModel: vm)
}

#Preview("Sign up") {
    let auth = AuthenticationManagerImpl.shared
    let user = UserManagerImpl(authenticationManager: auth)
    let vm = AuthViewModel(authenticationManager: auth, userManager: user)
    vm.mode = .signUp
    return AuthView(viewModel: vm)
}
#endif

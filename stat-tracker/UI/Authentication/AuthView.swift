//
//  AuthView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 17.5.2025.
//

import SwiftUI

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthenticationManagerImpl
    @ObservedObject var viewModel: AuthViewModel
    
    @State private var credentials = Credentials(username: "", password: "")
    @State private var isAuthenticated = false // This will be updated via onReceive from authManager

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            TextField("Username", text: $credentials.username)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $credentials.password)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if viewModel.overallLoading {
                ProgressView("Authenticating...")
                    .padding()
            } else {
                Button("Login") {
                    viewModel.login(credentials: credentials)
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .disabled(credentials.username.isEmpty || credentials.password.isEmpty || viewModel.overallLoading)
            }
            
            if isAuthenticated {
                Text("Authentication Successful!")
                    .padding()
            }
        }
        .padding()
        .onDisappear {
            viewModel.errorMessage = nil
            viewModel.overallLoading = false
        }
        .onReceive(authManager.$isAuthenticated) { authStatus in
            isAuthenticated = authStatus
        }
    }
}

//struct AuthView_Previews: PreviewProvider {
//    static var previews: some View {
//        let factory = AppViewModelFactory()
//        let authViewModel = factory.createAuthViewModel()
//        AuthView(viewModel: authViewModel)
//            .environmentObject(AuthenticationManagerImpl())
//    }
//}

//
//  Login.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var apiService = APIService.shared
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .bold()
                .padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                performLogin()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "Signing In..." : "Sign In")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
            .padding()
            
//            Button(action: {
//                performLogin()
//            }) {
//                Text("Sign In")
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(8)
//            }
//            .padding()
        }
        .padding()
    }
    
    private func performLogin() {
        guard !email.isEmpty && !password.isEmpty else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await apiService.login(username: email, password: password)
                
                await MainActor.run {
                    isLoading = false
                    // 登录成功，可以关闭登录界面或导航到主界面
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

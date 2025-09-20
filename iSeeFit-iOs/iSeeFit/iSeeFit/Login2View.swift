//
//  Login2View.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//

//
//  LoginView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-19.
//

import SwiftUI

struct Login2View: View {
    @StateObject private var apiService = APIService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var isLoginMode = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text(isLoginMode ? "Welcome Back" : "Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isLoginMode ? "Sign in to save your meal records" : "Join iSeeFit to track your nutrition")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 16) {
                    if !isLoginMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                        TextField("Enter your username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, 24)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: performAction) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(isLoading ? "Please wait..." : (isLoginMode ? "Sign In" : "Create Account"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || username.isEmpty || password.isEmpty || (!isLoginMode && email.isEmpty))
                    
                    Button(action: toggleMode) {
                        Text(isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Sign in")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Demo Account Info
                VStack(spacing: 8) {
                    Text("Demo Account")
                        .font(.headline)
                    Text("Username: testuser")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Password: password123")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func performAction() {
        guard !username.isEmpty && !password.isEmpty else { return }
        
        if !isLoginMode && email.isEmpty {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isLoginMode {
                    _ = try await apiService.login(username: username, password: password)
                } else {
                    _ = try await apiService.register(username: username, email: email, password: password)
                    // Auto-login after registration
                    _ = try await apiService.login(username: username, password: password)
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
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
    
    private func toggleMode() {
        isLoginMode.toggle()
        errorMessage = ""
    }
}

struct Login2View_Previews: PreviewProvider {
    static var previews: some View {
        Login2View()
    }
}

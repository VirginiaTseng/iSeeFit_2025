//
//  PrivacyPolicyView.swift
//  iSeeFit
//
//  A simple privacy policy view describing how user data is protected.
//  Includes: right to be forgotten, opt-in cloud storage, and ephemeral
//  recommendation input data handling. Debug logs are included.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionTitle("Your Privacy Matters")
                    sectionBody(
                        "We take your privacy seriously. This page explains how your personal data is collected, used, and protected in iSeeFit.")
                    
                    sectionTitle("Right to be Forgotten")
                    sectionBody(
                        "You have the right to request deletion of your account and associated personal data at any time. Upon confirmation, we will permanently remove your data from our systems.")
                    
                    sectionTitle("Optional Cloud Storage")
                    sectionBody(
                        "Your data (e.g., weight history, meal history) is only stored in the cloud if you explicitly enable cloud sync in Settings. If cloud sync is turned off, data remains stored locally on your device.")
                    
                    sectionTitle("Ephemeral Recommendation Inputs")
                    sectionBody(
                        "To generate personalized recommendations, the app may temporarily process your weight history, meal history, and related metrics. These input datasets are used in-memory to compute recommendations and are not retained on the server after the recommendation is produced.")
                    
                    sectionTitle("Data Security")
                    sectionBody(
                        "We follow industry best practices to protect your data. Communications are encrypted in transit, and sensitive data is protected at rest according to platform capabilities.")
                    
                    sectionTitle("Your Controls")
                    bulletList([
                        "Export or delete your data upon request.",
                        "Turn cloud sync on/off in Settings at any time.",
                        "Manage authentication and revoke access tokens by logging out.",
                    ])
                    
                    sectionTitle("Contact")
                    sectionBody(
                        "If you have any questions about privacy or data protection, please contact our support team.")
                }
                .padding(20)
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("DEBUG: PrivacyPolicyView - dismiss tapped")
                        dismiss()
                    }
                }
            }
        }
        .onAppear { print("DEBUG: PrivacyPolicyView - appeared") }
    }
    
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
    }
    
    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").font(.headline)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}



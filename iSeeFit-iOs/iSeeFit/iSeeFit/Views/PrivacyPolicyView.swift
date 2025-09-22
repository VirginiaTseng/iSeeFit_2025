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
                VStack(spacing: 18) {
                    headerCard()
                    
                    sectionCard(
                        title: "Right to be Forgotten",
                        icon: "person.crop.circle.badge.xmark",
                        tint: .red,
                        body: "You have the right to request deletion of your account and associated personal data at any time. Upon confirmation, we will permanently remove your data from our systems."
                    )
                    
                    sectionCard(
                        title: "Optional Cloud Storage",
                        icon: "icloud",
                        tint: .blue,
                        body: "Your data (e.g., weight history, meal history) is only stored in the cloud if you explicitly enable cloud sync in Settings. If cloud sync is turned off, data remains stored locally on your device."
                    )
                    
                    sectionCard(
                        title: "Ephemeral Recommendation Inputs",
                        icon: "sparkles",
                        tint: .purple,
                        body: "To generate personalized recommendations, the app may temporarily process your weight history, meal history, and related metrics. These input datasets are used in-memory to compute recommendations and are not retained on the server after the recommendation is produced."
                    )
                    
                    sectionCard(
                        title: "Data Security",
                        icon: "lock.shield",
                        tint: .green,
                        body: "We follow industry best practices to protect your data. Communications are encrypted in transit, and sensitive data is protected at rest according to platform capabilities."
                    )
                    
                    controlsCard()
                    contactCard()
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
    
    // MARK: - Styled Sections
    private func headerCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Privacy Matters")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("This page explains how your personal data is collected, used, and protected in iSeeFit.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func sectionCard(title: String, icon: String, tint: Color, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tint.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .foregroundColor(tint)
                        .font(.subheadline)
                }
                Text(title)
                    .font(.headline)
            }
            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func controlsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.orange)
                        .font(.subheadline)
                }
                Text("Your Controls")
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 8) {
                bulletRow("Export or delete your data upon request.")
                bulletRow("Turn cloud sync on/off in Settings at any time.")
                bulletRow("Manage authentication and revoke access tokens by logging out.")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func contactCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.teal.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.teal)
                        .font(.subheadline)
                }
                Text("Contact")
                    .font(.headline)
            }
            Text("If you have any questions about privacy or data protection, please contact our support team.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(1.5)
        }
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
    }
}



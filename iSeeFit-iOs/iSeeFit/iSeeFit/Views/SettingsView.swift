//
//  SettingsView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import SwiftUI

struct SettingsView: View {
    @State private var iCloudSyncOn: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    vipCard
                    quickGrid
                    widgetWatchCard
                    settingsList
                    NotificationCard()
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text("Profile").font(.headline) } }
            .background(LinearGradient(colors: [Color.black.opacity(0.05), Color.clear], startPoint: .top, endPoint: .bottom))
        }
        
        
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.yellow.opacity(0.2))
                    .frame(width: 54, height: 54)
                Image(systemName: "star.fill").foregroundColor(.orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("iSeeFit").font(.headline)
                    Text("Lifetime")
                        .font(.caption2)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(6)
                }
                Text("Expires On: Forever").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var vipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("VIP").font(.title3).bold().foregroundColor(.yellow)
                Text("Pro Member").font(.title3).bold()
                Spacer()
            }
            Text("Enjoy 7 Exclusive Benefits").font(.subheadline).foregroundColor(.secondary)
            HStack(spacing: 12) {
                CapsuleButton(title: "Benefits", icon: "crown.fill", filled: false)
                CapsuleButton(title: "Unlocked", icon: "lock.open.fill", filled: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    private var quickGrid: some View {
        VStack(spacing: 0) {
            HStack { featureItem(title: "My Stars", systemImage: "sparkles") ; Divider().frame(height: 44); featureItem(title: "Starrealm", systemImage: "dice") ; Divider().frame(height: 44); featureItem(title: "Penalty Event", systemImage: "face.dashed") }
                .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private func featureItem(title: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage).font(.title3).foregroundColor(.orange)
            Text(title).font(.footnote)
        }
        .frame(maxWidth: .infinity)
    }

    private var widgetWatchCard: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.15)).frame(width: 28, height: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("My widget").font(.subheadline)
                        Text("9/9").font(.caption2).foregroundColor(.secondary)
                    }
                }
                Spacer()
                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1, height: 36)
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "applewatch.watchface").foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("My Watch").font(.subheadline)
                        Text("Filled with Stars").font(.caption2).foregroundColor(.secondary)
                    }
                }
            }.padding(16)
        }
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var settingsList: some View {
        VStack(spacing: 8) {
            AppSettingsRow(icon: "gearshape.fill", title: "Settings")
            AppSettingsRow(icon: "textformat.alt", title: "Language Settings")
            AppToggleRow(icon: "icloud", title: "iCloud Sync", isOn: $iCloudSyncOn)
            Text("Data will be backed up to iCloud")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
            AppSettingsRow(icon: "message.fill", title: "Feedback")
            AppSettingsRow(icon: "book.fill", title: "RedNote")
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

private struct CapsuleButton: View {
    let title: String
    let icon: String
    let filled: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            Capsule().fill(filled ? Color.brown.opacity(0.9) : Color.white.opacity(0.8))
        )
        .foregroundColor(filled ? .white : .brown)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

private struct AppSettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
    }
}

private struct AppToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.gray)
            Text(title)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}



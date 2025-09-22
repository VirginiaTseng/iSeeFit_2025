//
//  SettingsView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var apiService = APIService.shared
    @State private var iCloudSyncOn: Bool = false
    @State private var showLogin = false
    @State private var showLogoutAlert = false
    @State private var showUserDetails = false  // 新增：控制用户详细信息显示
    @State private var showPrivacy = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 根据登录状态显示不同的头部
                    if apiService.isAuthenticated, let user = apiService.currentUser {
                        userInfoCard(user: user)
                    } else {
                        headerCard
                    }
                    
                    vipCard
                    quickGrid
                    widgetWatchCard
                    settingsList
            // Privacy entry at the bottom
            Button(action: {
                print("DEBUG: SettingsView - open PrivacyPolicyView")
                showPrivacy = true
            }) {
                HStack {
                    Image(systemName: "hand.raised.fill").foregroundColor(.gray)
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.gray)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            }
                    NotificationCard()
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { ToolbarItem(placement: .principal) { Text("Profile").font(.headline) } }
            .background(LinearGradient(colors: [Color.black.opacity(0.05), Color.clear], startPoint: .top, endPoint: .bottom))
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
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
                                        // 根据登录状态显示不同的文本
                    if apiService.isAuthenticated, let user = apiService.currentUser {
                        Text(user.username)
                            .font(.headline)
                    } else {
                        Text("iSeeFit")
                            .font(.headline)
                    }
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
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
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
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
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
            
            // 根据登录状态显示不同的选项
            if apiService.isAuthenticated {
                AppSettingsRow(icon: "arrow.right.square", title: "Logout", action: {
                    showLogoutAlert = true
                })
            } else {
                AppSettingsRow(icon: "person.badge.plus", title: "Sign In", action: {
                    showLogin = true
                })
            }
            
            AppSettingsRow(icon: "message.fill", title: "Feedback")
            AppSettingsRow(icon: "book.fill", title: "RedNote")
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.1)))
    }
    
    // 新增：用户信息卡片
    private func userInfoCard(user: UserResponse) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.2))
                        .frame(width: 54, height: 54)
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                
                 VStack(alignment: .leading, spacing: 4) {
                     HStack(spacing: 8) {
                         Text(user.username)
                             .font(.headline)
                         Text("Member")
                             .font(.caption2)
                             .padding(.vertical, 2)
                             .padding(.horizontal, 6)
                             .background(Color.blue.opacity(0.15))
                             .cornerRadius(6)
                     }
                     Text(user.email)
                         .font(.caption)
                         .foregroundColor(.secondary)
                 }
                 
                 Spacer()
                 
                 // 添加切换按钮
                 Button(action: {
                     withAnimation(.easeInOut(duration: 0.3)) {
                         showUserDetails.toggle()
                     }
                 }) {
                     Image(systemName: showUserDetails ? "chevron.up" : "chevron.down")
                         .foregroundColor(.blue)
                         .font(.title3)
                 }
                 
                 Button(action: {
                     showLogoutAlert = true
                 }) {
                     Image(systemName: "arrow.right.square")
                         .foregroundColor(.red)
                         .font(.title3)
                 }
            }
            
            
            // 用户详细信息 - 根据状态显示
            if showUserDetails {
                VStack(spacing: 8) {
                if let fullName = user.full_name {
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Full Name")
                        Spacer()
                        Text(fullName)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let age = user.age {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Age")
                        Spacer()
                        Text("\(age) years old")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let height = user.height, let weight = user.weight {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Height")
                        Spacer()
                        Text("\(String(format: "%.1f", height)) cm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Weight")
                        Spacer()
                        Text("\(String(format: "%.1f", weight)) kg")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let gender = user.gender {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Gender")
                        Spacer()
                        Text(gender.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let activityLevel = user.activity_level {
                    HStack {
                        Image(systemName: "figure.run")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Activity Level")
                        Spacer()
                        Text(activityLevel.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let goal = user.goal {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        Text("Goal")
                        Spacer()
                        Text(goal.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    Text("Member Since")
                    Spacer()
                    Text(formatDate(user.created_at))
                        .foregroundColor(.secondary)
                }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
    
    private func logout() {
        apiService.logout()
        print("DEBUG: User logged out successfully")
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
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
    let action: (() -> Void)?
    
    init(icon: String, title: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Image(systemName: icon).foregroundColor(.gray)
                Text(title)
                Spacer()
                if action != nil {
                    Image(systemName: "chevron.right").foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        }
        .buttonStyle(PlainButtonStyle())
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
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}



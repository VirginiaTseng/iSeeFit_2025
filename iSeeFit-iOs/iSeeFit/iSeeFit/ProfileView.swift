//
//  ProfileView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//
import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 用户信息卡片
                    UserProfileCard()
                    
                    // 安全分数
                    SafetyScoreCard()
                    
                    // 紧急联系人
                    EmergencyContactsCard()
                    
                    // 设置选项
                    SettingsCard()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        Button(action: {}) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.purple)
                        }
                        Button(action: {}) {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.purple)
                        }
                        Button(action: {}) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
        }
    }
}

// 用户信息卡片
struct UserProfileCard: View {
    var body: some View {
        HStack(spacing: 15) {
            // 头像
            Image("profile_image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.purple, lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Emily Johnson")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.purple)
                }
                
                Text("emily.johnson@example.com")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// 安全分数卡片
struct SafetyScoreCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safety Score")
                .font(.headline)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green)
                        .frame(width: geometry.size.width * 0.85, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Spacer()
                Text("85%")
                    .font(.title2)
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// 紧急联系人卡片
struct EmergencyContactsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Emergency Contacts")
                    .font(.headline)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus")
                        .foregroundColor(.purple)
                }
            }
            
            ForEach(emergencyContacts) { contact in
                EmergencyContactRow(contact: contact)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// 紧急联系人数据模型
struct EmergencyContact: Identifiable {
    let id = UUID()
    let name: String
    let relation: String
}

// 示例数据
let emergencyContacts = [
    EmergencyContact(name: "David Johnson", relation: "Father"),
    EmergencyContact(name: "Marie Williams", relation: "Sister")
]

// 紧急联系人行
struct EmergencyContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.purple)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(contact.relation)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {}) {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                    )
            }
        }
    }
}

// 设置卡片
struct SettingsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings")
                .font(.headline)
            
            ForEach(settingsItems) { item in
                SettingsRow(item: item)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

// 设置项数据模型
struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let iconBackground: Color
    let iconColor: Color
}

// 示例数据
let settingsItems = [
    SettingsItem(
        title: "Notifications",
        icon: "bell.fill",
        iconBackground: Color.purple.opacity(0.1),
        iconColor: .purple
    ),
    SettingsItem(
        title: "Privacy",
        icon: "lock.fill",
        iconBackground: Color.blue.opacity(0.1),
        iconColor: .blue
    ),
    SettingsItem(
        title: "Logout",
        icon: "arrow.right.square.fill",
        iconBackground: Color.red.opacity(0.1),
        iconColor: .red
    )
]

// 设置行
struct SettingsRow: View {
    let item: SettingsItem
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Circle()
                    .fill(item.iconBackground)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: item.icon)
                            .foregroundColor(item.iconColor)
                    )
                
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
} 

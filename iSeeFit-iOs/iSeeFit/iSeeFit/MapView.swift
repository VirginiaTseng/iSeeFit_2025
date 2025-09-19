//
//  MapView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import SwiftUI
import MapKit
import FirebaseCore
import FirebaseFirestore


struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    let firebaseDb = Firestore.firestore()
    
    @State private var searchText = ""
    @State private var reportStatus: String?
    
    @State private var showToast = false  // ⬅️ 是否显示弹窗
    @State private var toastMessage = ""  // ⬅️ 弹窗消息内容
    @State private var toastColor = Color.green // ⬅️ 消息颜色（成功: 绿，失败: 红）
    
//    @State private var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 52.1332, longitude: -106.6700),
//        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//    )
    
    func reportIncident(latitude: Double, longitude: Double) {
        let timestamp = Int(Date().timeIntervalSince1970)
            let userRef = firebaseDb.collection("events").document("user_123-\(timestamp)")
            
            userRef.setData([
               "description": "Fire outbreak detected",
               "location": GeoPoint(latitude:latitude,longitude:longitude ), // 经纬度格式
               "timestamp": timestamp * 1000, // 转换为毫秒级时间戳
               "type": "emergency"
            ]) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                    reportStatus="Faied to send report❌"
                    toastMessage = "❌ Report Failed"
                    toastColor = .red
                } else {
                    print("Document added successfully!")
                    reportStatus="Report Sent✅"
                    toastMessage = "✅ Report Sent Successfully"
                    toastColor = .green
                }
                
                showToast = true // 显示 Toast
                hideToastAfterDelay() // 自动隐藏
            }
        
        //Realtime Database
//            let usersRef = ref.child("users").childByAutoId()
//                usersRef.setValue([
//                    "name": "John Doe",
//                    "age": 25,
//                    "email": "john@example.com"
//                ]) { error, _ in
//                    if let error = error {
//                        print("Error adding data: \(error.localizedDescription)")
//                    } else {
//                        print("Data added successfully!")
//                    }
//                }
        }
    
    // 自动隐藏 Toast（2 秒后）
        func hideToastAfterDelay() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showToast = false
            }
        }

    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let location = locationManager.location {
                    HStack {
                        Text("Lati: \(location.coordinate.latitude)")
                        Text("Long: \(location.coordinate.longitude)")
                        Button("Report") {
                            reportIncident(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                        }
                    }
              } else {
                  Text("Fetching location...")
              }
                // 搜索栏和过滤器
                VStack(spacing: 16) {
                  
                    // 搜索栏
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search location...", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // 过滤器按钮
                    HStack(spacing: 12) {
                        FilterButton(title: "Safe Routes", icon: "shield.fill", color: .blue)
                        FilterButton(title: "Risk Areas", icon: "exclamationmark.triangle.fill", color: .red)
                        FilterButton(title: "Help Points", icon: "cross.fill", color: .green)
                    }
                }
                .padding()
                .background(Color.white)
                
                // 地图视图
                ZStack(alignment: .trailing) {
                    Map(coordinateRegion: $locationManager.region,
                        showsUserLocation: true,
                        userTrackingMode: .constant(.follow))
                        .edgesIgnoringSafeArea(.bottom)
                    
                    // 地图控制按钮
                    VStack(spacing: 8) {
                        MapControlButton(icon: "layers.fill") {}
                        MapControlButton(icon: "location.fill") {
                            // 重新定位到用户位置
                            if let location = locationManager.location {
                                withAnimation {
                                    locationManager.region = MKCoordinateRegion(
                                        center: location.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                    )
                                }
                            }
                        }
                        MapControlButton(icon: "plus") {}
                        MapControlButton(icon: "minus") {}
                    }
                    .padding(.trailing)
                }
                
                
                // 底部信息卡片
                VStack(spacing: 16) {
                    // 风险等级
                    HStack(spacing: 20) {
                        RiskLevelCard(
                            title: "Risk Level",
                            value: "Moderate",
                            subtitle: "Current Area",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .orange
                        )
                        
                        RiskLevelCard(
                            title: "Incidents",
                            value: "3",
                            subtitle: "Last 24 hours",
                            icon: "exclamationmark.circle.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.white)
            }
            .commonToolbar()
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    HStack(spacing: 15) {
//                        Button(action: {}) {
//                            Image(systemName: "bell.fill")
//                                .foregroundColor(.purple)
//                        }
//                        Button(action: {}) {
//                            Image(systemName: "moon.fill")
//                                .foregroundColor(.purple)
//                        }
//                        Button(action: {}) {
//                            Image(systemName: "mic.fill")
//                                .foregroundColor(.purple)
//                        }
//                    }
//                }
//            }
            
            if showToast {
                            VStack {
                                Spacer()
                                Text(toastMessage)
                                    .padding()
                                    .background(toastColor.opacity(0.9))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .transition(.opacity)
                                    .animation(.easeInOut, value: showToast)
                            }
                            .padding(.bottom, 50)
                        }
        }
    }
    
    
}

// 过滤器按钮
struct FilterButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(20)
        }
    }
}

// 地图控制按钮
struct MapControlButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
        }
    }
}

// 风险等级卡片
struct RiskLevelCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline)
                    .foregroundColor(color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .cornerRadius(8)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// 预览
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
} 

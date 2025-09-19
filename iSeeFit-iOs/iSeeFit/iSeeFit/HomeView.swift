import SwiftUI

struct HomeView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    // 定义通知使用的图片名称
    private let notificationImages = [
        "safe-zone": UIImage(systemName: "checkmark.shield.fill")!,
        "alert-high": UIImage(systemName: "exclamationmark.triangle.fill")!,
        "alert-medium": UIImage(systemName: "exclamationmark.circle.fill")!,
        "alert-low": UIImage(systemName: "info.circle.fill")!
    ]
    
    func saveSystemImageToAssets() {
           // 确保文档目录可用
           guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
               return
           }
           
           // 保存每个系统图片
           for (name, image) in notificationImages {
               let fileURL = documentsDirectory.appendingPathComponent("\(name).png")
               
               // 将 UIImage 转换为 PNG 数据
               if let data = image.pngData() {
                   // 写入文件
                   try? data.write(to: fileURL)
                   
                   // 创建通知附件
                   notificationManager.sendNotificationWithImage(
                       title: "Safety Update",
                       body: "Your area is currently safe",
                       imageName: name,
                       imageURL: fileURL
                   )
               }
           }
       }
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 安全状态卡片
                    SafetyStatusCard()//
                    
                    // 快速操作按钮
                    QuickActionsView()
                    
                    // 天气和安全信息
                    WeatherSafetyCard()
                    
                    // 最近活动
                    RecentActivityCard()
                    
                    if !notificationManager.isAuthorized {
                                          Button("Enable Notifications") {
                                              notificationManager.requestAuthorization()
                                          }
                                          .padding()
                                          .background(Color.purple.opacity(0.1))
                                          .cornerRadius(10)
                                      }
                    Button("Send Test Notification") {
                                                 notificationManager.sendTestNotification()
                                             }
                                             .padding()
                                             .background(Color.blue.opacity(0.1))
                                             .cornerRadius(10)
                                              
                                              Button("Send Automatic Test Notification") {
                                                 // notificationManager.sendTestNotification()
                                                  // 设置每30分钟发送一次通知
                                                  notificationManager.scheduleDefaultReminders()
                          //                            .scheduleNotification(
                          //                            title: "iSeeFit Safety Reminder",
                          //                            body: "Regular safety check reminder",
                          //                            interval: 1800 // 30 minutes in seconds
                          //                        )
                                              }
                                              
                                              Button("Send Safety Alert") {
                                                  notificationManager.sendSafetyAlert(
                                                      level: "High",
                                                      message: "Unusual activity detected in your area"
                                                  )
                                              }

                                              Button("Send Image Notification") {
                                                  notificationManager.sendNotificationWithImage(
                                                      title: "Safety Update",
                                                      body: "Your area is currently safe",
                                                      imageName: "safe-zone"  // 确保在 Assets.xcassets 中有这个图片
                                                  )
                                              }
                                              .padding()
                                              .background(Color.blue.opacity(0.1))
                                              .cornerRadius(10)
                                              
                                              // 测试按钮
                                               Button("Send Notification with Image222") {
                                                   saveSystemImageToAssets()
                                               }
                                               .padding()
                                               .background(Color.blue.opacity(0.1))
                                               .cornerRadius(10)
                    
                            Button("Reset Onboarding") {
                                UserDefaults.standard.setValue(false, forKey:"hasSeenOnboarding")//.removeObject(forKey: "hasSeenOnboarding")
                                    print("🛠️ Debug: hasSeenOnboarding reset to false") // ✅ Debug Log
                               // hasSeenOnboarding = false
                            }
                            .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    
                    
                }
                .padding()
                .background(Color.secondarySystemBackground)
            }
//            .navigationTitle("iSeeFit")
            .commonToolbar(
                notificationAction: {
                    notificationManager.sendTestNotification()
                },
                darkModeAction: {
                   // isDarkMode.toggle()
                },
                voiceAction: {
                    // 处理语音功能
                }
            )
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    HStack(spacing: 15) {
//                        Button(action: {
//                            // 发送即时通知
////                            notificationManager.sendImmediateNotification(
////                                title: "iSeeFit Safety Alert",
////                                body: "Time to check your safety status!"
////                            )
//                        }) {
//                            Image(systemName: "bell.fill")
//                                .foregroundColor(.purple)
//                        }
//                        Button(action: {
//                        }) {
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
            .onAppear {
                notificationManager.requestAuthorization()
            }
        }
    }
}


// 安全状态卡片组件
struct SafetyStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Safety Status")
                    .font(.title2)
                    .bold()
                Spacer()
                Text("Protected")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(20)
            }
            
            Text("Last updated 5 min ago")
                .foregroundColor(.gray)
            
            HStack(spacing: 15) {
                StatusBox(title: "Safety Score", value: "85%", icon: "shield.fill")
                StatusBox(title: "Contacts", value: "5 active", icon: "person.2.fill")
                StatusBox(title: "Safe Zones", value: "3 zones", icon: "location.fill")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

// 状态框组件
struct StatusBox: View {
    var title: String
    var value: String
    var icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.purple)
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
}

// 快速操作按钮组件
struct QuickActionsView: View {
    var body: some View {
        HStack(spacing: 15) {
            ActionButton(
                title: "SOS Alert",
                subtitle: "Emergency help",
                icon: "exclamationmark.triangle.fill",
                backgroundColor: Color.red.opacity(0.1),
                iconColor: .red
            )
            
            ActionButton(
                title: "Safe Walk",
                subtitle: "Track journey",
                icon: "figure.walk",
                backgroundColor: Color.purple.opacity(0.1),
                iconColor: .purple
            )
        }
    }
}

struct ActionButton: View {
    var title: String
    var subtitle: String
    var icon: String
    var backgroundColor: Color
    var iconColor: Color
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
        }
    }
}

// 天气和安全信息卡片
struct WeatherSafetyCard: View {
    @StateObject private var weatherService = MoWeatherService()
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Weather & Safety")
                    .font(.title2)
                    .bold()
                Spacer()
                HStack {
                    Text("Updated \(Date(), style: .relative)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button(action: refreshWeather) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.purple)
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                    }
                }
            }
            
            HStack(spacing: 15) {
                // Weather Alert Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weather Alert")
                        .font(.headline)
                    if let weather = weatherService.weatherData {
                        HStack {
                            Image(systemName: getWeatherIcon(condition: weather.condition))
                            Text("\(Int(weather.temperature))°C")
                                .font(.title2)
                                .bold()
                        }
                        Text(weather.condition)
                        
                        // Weather Warnings
                        WeatherAlerts(temperature: weather.temperature)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // Safety Level Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Safety Level")
                        .font(.headline)
                    Image(systemName: "shield.fill")
                        .foregroundColor(.green)
                    Text("Safe")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Protected")
                            .font(.caption)
                        
                        Image(systemName: "house.fill")
                            .foregroundColor(.purple)
                        Text("Home Zone")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Environment Indicators
            HStack(spacing: 20) {
                if let weather = weatherService.weatherData {
                    EnvironmentIndicator(
                        icon: "sun.max.fill",
                        title: "UV Index",
                        value: getUVIndexDescription(weather.uvIndex),
                        iconColor: .orange
                    )
                    EnvironmentIndicator(
                        icon: "leaf.fill",
                        title: "Air Quality",
                        value: getAQIDescription(weather.airQuality),
                        iconColor: .green
                    )
                    EnvironmentIndicator(
                        icon: "eye.fill",
                        title: "Visibility",
                        value: getVisibilityDescription(weather.visibility),
                        iconColor: .blue
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
        .onAppear(perform: refreshWeather)
    }
    
    private func getUVIndexDescription(_ index: Int) -> String {
        switch index {
        case 0...2: return "Low"
        case 3...5: return "Moderate"
        case 6...7: return "High"
        case 8...10: return "Very High"
        default: return "Extreme"
        }
    }
    
    private func getAQIDescription(_ aqi: Int) -> String {
        switch aqi {
        case 0...50: return "Good"
        case 51...100: return "Moderate"
        case 101...150: return "Fair"
        default: return "Poor"
        }
    }
    
    private func getVisibilityDescription(_ visibility: Double) -> String {
        if visibility > 10 {
            return "Clear"
        } else if visibility > 5 {
            return "Good"
        } else {
            return "Limited"
        }
    }
    
    private func refreshWeather() {
        isLoading = true
        
        //mockData
        weatherService.fetchMockWeather()
        isLoading = false
        
//        Task {
//               await weatherService.fetchWeather(latitude: 43.6532, longitude: -79.3832)
//               await MainActor.run {
//                   isLoading = false
//               }
//           }
    }
    
    func getWeatherIcon(condition: String) -> String {
        switch condition.lowercased() {
        case "clear":
            return "sun.max"
        case "cloudy":
            return "cloud"
        case "partly cloudy":
            return "cloud.sun"
        case "rain":
            return "cloud.rain"
        case "snow":
            return "cloud.snow"
        case "thunderstorm":
            return "cloud.bolt"
        default:
            return "questionmark"
        }
    }
}

struct WeatherAlerts: View {
    let temperature: Double
    
    var body: some View {
        HStack {
            if temperature < 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Icy Roads")
                    .font(.caption)
            }
            
            if temperature < -5 {
                Image(systemName: "eye.slash")
                    .foregroundColor(.gray)
                Text("Low Visibility")
                    .font(.caption)
            }
        }
    }
}

struct EnvironmentIndicator: View {
    var icon: String
    var title: String
    var value: String
    var iconColor: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text(value)
                .font(.subheadline)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// 最近活动卡片
struct RecentActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Activity")
                .font(.title2)
                .bold()
            
            ForEach(0..<3) { _ in
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    Text("Safe zone check-in")
                        .font(.subheadline)
                    Spacer()
                    Text("2 min ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

// 预览
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

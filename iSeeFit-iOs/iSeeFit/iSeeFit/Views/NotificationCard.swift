//
//  NotificationCard.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//
import SwiftUI


struct NotificationCard: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    // 定义通知使用的图片名称
    private let notificationImages = [
        "safe-zone": UIImage(systemName: "checkmark.shield.fill")!,
        "alert-high": UIImage(systemName: "exclamationmark.triangle.fill")!,
        "alert-medium": UIImage(systemName: "exclamationmark.circle.fill")!,
        "alert-low": UIImage(systemName: "info.circle.fill")!
    ]
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
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
                print("🔄 User requested to start automatic notifications")
                notificationManager.scheduleDefaultReminders()
                print("✅ Automatic notifications scheduled successfully")
//                            .scheduleNotification(
//                            title: "iSeeFit Safety Reminder",
//                            body: "Regular safety check reminder",
//                            interval: 1800 // 30 minutes in seconds
//                        )
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            
            // 停止自动通知按钮
            Button("Stop Automatic Notifications") {
                // 停止所有自动通知
                print("🛑 User requested to stop automatic notifications")
                notificationManager.stopAutomaticNotifications()
                print("✅ Automatic notifications stopped successfully")
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
            
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
                UserDefaults.standard.setValue(false, forKey:"hasSeenIntro")
                UserDefaults.standard.setValue(false, forKey:"hasSeenOnboarding")//.removeObject(forKey: "hasSeenOnboarding")
                // hasSeenOnboarding = false
            }
            .padding()


            Button("debugNotification") {
                        notificationManager.debugDumpNotifications()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)

                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            Button("removeNotification") {
                        notificationManager.removeNotification()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)

                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
            Button("checkNotification") {
                        notificationManager.debugDumpNotifications()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)

                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            
        }
    }
    
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
}

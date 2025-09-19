//
//  NotificationManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-20.
//

import UserNotifications
import SwiftUI
import UIKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
        setupNotificationCategories()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                print("Notification Status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    print("✅ Notification permission granted")
                    self.scheduleDefaultReminders()
                } else {
                    print("❌ Notification permission denied")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // 发送即时测试通知
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "If you see this, notifications are working!"
        content.sound = .default
        
        // 2秒后触发
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling test notification: \(error)")
            } else {
                print("✅ Test notification scheduled successfully")
            }
        }
    }
    
    // 设置定期提醒
    func scheduleDefaultReminders() {
        // 取消现有的提醒
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Safety Check"
        content.body = "Time to check your safety status!"
        content.sound = .default
        
        // 创建每30分钟触发一次的触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "safety-check",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling reminder: \(error)")
            } else {
                print("✅ Regular reminders scheduled successfully")
            }
        }
    }
    
    // 设置通知类别和按钮
    private func setupNotificationCategories() {
        // 定义操作按钮
        let checkAction = UNNotificationAction(
            identifier: "CHECK_ACTION",
            title: "Check Status",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: .destructive
        )
        
        // 创建通知类别
        let safetyCategory = UNNotificationCategory(
            identifier: "SAFETY_ALERT",
            actions: [checkAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // 注册通知类别
        UNUserNotificationCenter.current().setNotificationCategories([safetyCategory])
    }
    
    // 发送带图片的通知
    func sendNotificationWithImage(title: String, body: String, imageName: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "SAFETY_ALERT"
        
        // 添加徽章数字
        content.badge = 1
        
        // 设置通知的线程标识符（用于分组）
        content.threadIdentifier = "safety-alerts"
        
        // 添加自定义数据
        content.userInfo = ["type": "safety-alert"]
        
        // 添加图片附件
        if let imageURL = Bundle.main.url(forResource: imageName, withExtension: "png") {
            do {
                let attachment = try UNNotificationAttachment(
                    identifier: UUID().uuidString,
                    url: imageURL,
                    options: [
                        UNNotificationAttachmentOptionsTypeHintKey: "image/png",
                        UNNotificationAttachmentOptionsThumbnailHiddenKey: false
                    ]
                )
                content.attachments = [attachment]
            } catch {
                print("❌ Error adding attachment: \(error)")
            }
        }
        
        // 2秒后触发
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Notification with image scheduled successfully")
            }
        }
    }
    
    func sendNotificationWithImage(title: String, body: String, imageName: String, imageURL: URL) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "SAFETY_ALERT"
        
        do {
            let attachment = try UNNotificationAttachment(
                identifier: UUID().uuidString,
                url: imageURL,
                options: [
                    UNNotificationAttachmentOptionsTypeHintKey: "image/png",
                    UNNotificationAttachmentOptionsThumbnailHiddenKey: false
                ]
            )
            content.attachments = [attachment]
        } catch {
            print("❌ Error adding attachment: \(error)")
        }
        
        // 2秒后触发
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Notification with image scheduled successfully")
            }
        }
    }
    
    // 发送自定义样式的安全提醒
    func sendSafetyAlert(level: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Safety Alert"
        content.subtitle = "Alert Level: \(level)"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "SAFETY_ALERT"
        
        // 根据安全级别设置不同的图片
        let imageName: String
        switch level.lowercased() {
        case "high":
            imageName = "alert-high"
        case "medium":
            imageName = "alert-medium"
        default:
            imageName = "alert-low"
        }
        
        if let imageURL = Bundle.main.url(forResource: imageName, withExtension: "png") {
            do {
                let attachment = try UNNotificationAttachment(
                    identifier: UUID().uuidString,
                    url: imageURL,
                    options: nil
                )
                content.attachments = [attachment]
            } catch {
                print("❌ Error adding attachment: \(error)")
            }
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // 处理通知响应
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case "CHECK_ACTION":
            print("User tapped Check Status")
            // 处理检查状态操作
        case "DISMISS_ACTION":
            print("User dismissed the notification")
            // 处理关闭通知操作
        default:
            break
        }
        completionHandler()
    }
    
    // 处理前台通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 允许在前台显示通知
        completionHandler([.banner, .sound, .badge])
    }
}

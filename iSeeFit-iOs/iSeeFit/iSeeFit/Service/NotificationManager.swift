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
                    //self.scheduleDefaultReminders()
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
        // UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // let content = UNMutableNotificationContent()
        // content.title = "Safety Check"
        // content.body = "Time to check your safety status!"
        // content.sound = .default
        
        // // 创建每30分钟触发一次的触发器
        // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: true)
        
        // let request = UNNotificationRequest(
        //     identifier: "safety-check",
        //     content: content,
        //     trigger: trigger
        // )
        
        // UNUserNotificationCenter.current().add(request) { error in
        //     if let error = error {
        //         print("❌ Error scheduling reminder: \(error)")
        //     } else {
        //         print("✅ Regular reminders scheduled successfully")
        //     }
        // }
    }
    
    // 停止自动通知
    func stopAutomaticNotifications() {
        // 取消所有待发送的通知请求
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // 清除通知中心的所有通知
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        print("✅ All automatic notifications have been stopped and cleared")

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["safety-check"])
        center.removeDeliveredNotifications(withIdentifiers: ["safety-check"])
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
                    identifier: "iseefit-notification",
                    url: imageURL,
                    options: [
                        UNNotificationAttachmentOptionsTypeHintKey: "image/png",
                        UNNotificationAttachmentOptionsThumbnailHiddenKey: false
                    ]
                )
                content.attachments = [attachment]
            } catch {
                print("Error adding attachment: \(error)")
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
    
    
    
    // September 29, 2026
    
    // 1) 取消所有“待触发”的通知（还没弹出来的）
    func cancelAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // 2) 取消所有“已送达”的通知（通知中心里还在的卡片）
    func clearAllDelivered() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // 3) 按标识符精准取消（适合 repeats: true 的通知）
    func cancel(by identifiers: [String]) {
        // 待触发的
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        // 已送达的
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }


    
    //“统一关闭”入口（比如在设置页放一个按钮）
    func nukeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    //取消一个重复提醒的范式（示例）
    func scheduleDaily(id: String, hour: Int, minute: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        // 先确保同名的旧通知被移除，避免重复
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().add(request)
    }

    func cancelDaily(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
    }

    //如果是远程推送（APNs）
    
   // 本地代码无法“撤回服务器已发出的未来推送”；需要你们的服务端停止推送或改逻辑。

    //已经送达的远程通知卡片，也只能清理“已送达”的本地记录：removeDeliveredNotifications。
    //你可以先调 debugListAll() 看看现在到底有哪些通知在排队；若一键清空后过一会儿又出现，多半是你的代码某处在重复安排。把你安排通知的那段代码贴过来，我可以帮你做一次“防重复 + 可撤销”的重构版本。
    
    // 4) 调试用：打印目前有哪些待触发/已送达的通知
    func debugListAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            print("PENDING (\(reqs.count)):")
            reqs.forEach { print(" - \($0.identifier) | \($0.content.title)") }
        }
        center.getDeliveredNotifications { notis in
            print("DELIVERED (\(notis.count)):")
            notis.forEach { print(" - \($0.request.identifier) | \(notis.last?.request.content.title ?? "")") }
        }
    }

    func debugDumpNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            print("PENDING=\(reqs.count)")
            for r in reqs {
                let t = String(describing: type(of: r.trigger))
                print(" • [PENDING] id=\(r.identifier) trigger=\(t) title=\(r.content.title)")
            }
        }
        center.getDeliveredNotifications { notis in
            print("DELIVERED=\(notis.count)")
            for n in notis {
                let r = n.request
                let t = String(describing: type(of: r.trigger))
                print(" • [DELIVERED] id=\(r.identifier) trigger=\(t) title=\(r.content.title)")
            }
        }
    }

    
    
    func removeNotification(){
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["safety-check"])
        center.removeDeliveredNotifications(withIdentifiers: ["safety-check"])

    }
}

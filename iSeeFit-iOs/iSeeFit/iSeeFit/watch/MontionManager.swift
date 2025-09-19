//
//  MontionManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import CoreMotion
import WatchConnectivity

class MotionManager {
    private let motionManager = CMMotionManager()
    
    func startMonitoringMotion() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                guard let acceleration = data?.acceleration else { return }
                
                // 检测震动
                let threshold = 2.0
                if abs(acceleration.x) > threshold ||
                   abs(acceleration.y) > threshold ||
                   abs(acceleration.z) > threshold {
                    self.sendShockDataToPhone()
                }
            }
        }
    }
    
    private func sendShockDataToPhone() {
        if WCSession.default.isReachable {
            let message: [String: Any] = ["type": "shock", "timestamp": Date()]
//            WCSession.default.sendMessage(message, replyHandler: nil)
            WCSession.default.sendMessage(message, replyHandler: { _ in
                           // 处理成功回调
                       }, errorHandler: { error in
                           print("发送消息错误: \(error.localizedDescription)")
                       })
        }
    }
}


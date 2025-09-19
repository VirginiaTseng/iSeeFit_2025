//
//  ViewController.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//
import UIKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWatchConnection()
    }
    
    private func setupWatchConnection() {
        if WCSession.isSupported() {
                 let session = WCSession.default
                 session.delegate = self
                 session.activate()
             }
        
        

        
//        ConnectionManager.shared // 初始化连接
//        
//        // 接收来自手表的消息
//        WCSession.default.receive { message in
//            switch message["type"] as? String {
//            case "shock":
//                self.handleShockData(message)
//            case "voice":
//                self.handleVoiceData(message)
//            default:
//                break
//            }
//        }
    }
    
    
    // WCSessionDelegate 必需的方法
       func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
       
       func sessionDidBecomeInactive(_ session: WCSession) {}
       
       func sessionDidDeactivate(_ session: WCSession) {}
       
       // 接收消息的方法
       func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
           DispatchQueue.main.async {
               switch message["type"] as? String {
               case "shock":
                   self.handleShockData(message)
               case "voice":
                   self.handleVoiceData(message)
               default:
                   break
               }
           }
       }

    
    private func handleShockData(_ message: [String: Any]) {
        // 处理震动数据
        print("检测到震动，时间：\(message["timestamp"] ?? "")")
    }
    
    private func handleVoiceData(_ message: [String: Any]) {
        // 处理语音识别结果
        if let text = message["text"] as? String {
            print("语音识别结果：\(text)")
            // 这里可以添加进一步的语义分析
        }
    }
}

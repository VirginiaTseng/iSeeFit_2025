//
//  ConnectionManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import WatchConnectivity

class ConnectionManager: NSObject, WCSessionDelegate {
    static let shared = ConnectionManager()
    private var session: WCSession?
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // WCSessionDelegate 必需的方法
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}

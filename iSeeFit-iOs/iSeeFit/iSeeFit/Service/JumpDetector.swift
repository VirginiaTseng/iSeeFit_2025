//
//  JumpDetector.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-20.
//

import Foundation
import Vision
import SwiftUI

class JumpDetector: ObservableObject {
    @Published var jumpCount: Int = 0
    @Published var isJumping: Bool = false
    @Published var jumpHeight: Double = 0.0
    @Published var lastJumpTime: Date = Date()
    
    // 检测参数
    private let jumpThreshold: Double = 0.08  // 跳跃高度阈值
    private let minJumpInterval: TimeInterval = 0.5  // 最小跳跃间隔(秒)
    private let maxHistoryCount: Int = 10  // 最大历史记录数
    
    // 历史数据
    private var anklePositions: [AnkleData] = []
    private var jumpStates: [JumpState] = []
    
    private struct AnkleData {
        let timestamp: Date
        let leftAnkle: CGPoint
        let rightAnkle: CGPoint
        let averageY: Double
    }
    
    private enum JumpState {
        case idle
        case rising
        case falling
        case landed
    }
    
    init() {
        print("DEBUG: JumpDetector - Initialized")
    }
    
    func processKeyPoints(_ keyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        // 提取脚踝关键点
        guard let leftAnkle = keyPoints[.leftAnkle],
              let rightAnkle = keyPoints[.rightAnkle] else {
            print("DEBUG: JumpDetector - Missing ankle key points")
            return
        }
        
        // 计算平均脚踝位置
        let averageY = (leftAnkle.y + rightAnkle.y) / 2.0
        let ankleData = AnkleData(
            timestamp: Date(),
            leftAnkle: leftAnkle,
            rightAnkle: rightAnkle,
            averageY: averageY
        )
        
        // 添加到历史记录
        anklePositions.append(ankleData)
        
        // 保持历史记录长度
        if anklePositions.count > maxHistoryCount {
            anklePositions.removeFirst()
        }
        
        // 检测跳跃
        if anklePositions.count >= 3 {
            detectJump()
        }
        
        // 减少日志频率 - 每5次处理打印一次
        if anklePositions.count % 5 == 0 {
            print("DEBUG: JumpDetector - Processed ankle data: avgY=\(String(format: "%.3f", averageY)), history=\(anklePositions.count)")
        }
    }
    
    private func detectJump() {
        guard anklePositions.count >= 3 else { return }
        
        let recentData = Array(anklePositions.suffix(3))
        let currentY = recentData.last!.averageY
        let previousY = recentData[recentData.count - 2].averageY
        let beforePreviousY = recentData[recentData.count - 3].averageY
        
        // 计算高度变化
        let heightChange = previousY - currentY  // 向上为正
        let previousHeightChange = beforePreviousY - previousY
        
        // 检测跳跃模式
        let isRising = heightChange > 0.02  // 快速上升
        let wasFalling = previousHeightChange < -0.01  // 之前在下落
        let isSignificantRise = heightChange > jumpThreshold
        
        // 检查时间间隔
        let timeSinceLastJump = Date().timeIntervalSince(lastJumpTime)
        let canJump = timeSinceLastJump >= minJumpInterval
        
        // 只在检测到跳跃时打印详细日志
        if isRising && isSignificantRise {
            print("DEBUG: JumpDetector - Potential jump: height=\(String(format: "%.3f", heightChange)), canJump=\(canJump)")
        }
        
        // 检测跳跃条件
        if !isJumping && canJump && isRising && isSignificantRise {
            // 开始跳跃
            jumpCount += 1
            isJumping = true
            lastJumpTime = Date()
            jumpHeight = heightChange
            
            print("✅ JumpDetector - Jump detected! Count: \(jumpCount), Height: \(String(format: "%.3f", jumpHeight))")
            
            // 更新UI
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } else if isJumping && !isRising && heightChange < -0.02 {
            // 跳跃结束
            isJumping = false
            print("DEBUG: JumpDetector - Jump ended")
            
            // 更新UI
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    func reset() {
        jumpCount = 0
        isJumping = false
        jumpHeight = 0.0
        anklePositions.removeAll()
        jumpStates.removeAll()
        lastJumpTime = Date()
        print("DEBUG: JumpDetector - Reset")
    }
}

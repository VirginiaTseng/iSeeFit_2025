//
//  RotationDetector.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-20.
//

import Foundation
import Vision
import SwiftUI

class RotationDetector: ObservableObject {
    @Published var rotationCount: Int = 0
    @Published var isRotating: Bool = false
    @Published var currentAngle: Double = 0.0
    @Published var rotationDirection: RotationDirection = .none
    @Published var lastRotationTime: Date = Date()
    
    // 检测参数
    private let rotationThreshold: Double = 0.3  // 角度变化阈值(弧度)
    private let fullRotationThreshold: Double = 5.5  // 完整转圈阈值(弧度，约315度)
    private let minRotationInterval: TimeInterval = 1.0  // 最小转圈间隔(秒)
    private let maxHistoryCount: Int = 15  // 最大历史记录数
    
    // 历史数据
    private var shoulderAngles: [AngleData] = []
    private var bodyOrientations: [AngleData] = []
    private var rotationStates: [RotationState] = []
    
    private struct AngleData {
        let timestamp: Date
        let angle: Double
        let normalizedAngle: Double
    }
    
    private enum RotationState {
        case idle
        case rotating
        case completing
    }
    
    enum RotationDirection {
        case clockwise
        case counterClockwise
        case none
    }
    
    init() {
        print("DEBUG: RotationDetector - Initialized")
    }
    
    func processKeyPoints(_ keyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        // 提取肩膀和髋部关键点
        guard let leftShoulder = keyPoints[.leftShoulder],
              let rightShoulder = keyPoints[.rightShoulder],
              let leftHip = keyPoints[.leftHip],
              let rightHip = keyPoints[.rightHip] else {
            print("DEBUG: RotationDetector - Missing key points")
            return
        }
        
        // 计算肩膀角度
        let shoulderVector = CGPoint(
            x: rightShoulder.x - leftShoulder.x,
            y: rightShoulder.y - leftShoulder.y
        )
        let shoulderAngle = atan2(shoulderVector.y, shoulderVector.x)
        let normalizedShoulderAngle = normalizeAngle(shoulderAngle)
        
        // 计算身体朝向
        let bodyOrientation = calculateBodyOrientation(
            leftShoulder: leftShoulder,
            rightShoulder: rightShoulder,
            leftHip: leftHip,
            rightHip: rightHip
        )
        let normalizedBodyOrientation = normalizeAngle(bodyOrientation)
        
        // 添加到历史记录
        let shoulderData = AngleData(
            timestamp: Date(),
            angle: shoulderAngle,
            normalizedAngle: normalizedShoulderAngle
        )
        let bodyData = AngleData(
            timestamp: Date(),
            angle: bodyOrientation,
            normalizedAngle: normalizedBodyOrientation
        )
        
        shoulderAngles.append(shoulderData)
        bodyOrientations.append(bodyData)
        
        // 保持历史记录长度
        if shoulderAngles.count > maxHistoryCount {
            shoulderAngles.removeFirst()
            bodyOrientations.removeFirst()
        }
        
        // 检测转圈
        if shoulderAngles.count >= 5 {
            detectRotation()
        }
        
        // 减少日志频率 - 每10次处理打印一次
        if shoulderAngles.count % 10 == 0 {
            print("DEBUG: RotationDetector - Processed angles: shoulder=\(String(format: "%.3f", normalizedShoulderAngle)), body=\(String(format: "%.3f", normalizedBodyOrientation))")
        }
    }
    
    private func calculateBodyOrientation(
        leftShoulder: CGPoint,
        rightShoulder: CGPoint,
        leftHip: CGPoint,
        rightHip: CGPoint
    ) -> Double {
        // 计算肩膀和髋部的中心点
        let shoulderCenter = CGPoint(
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2
        )
        let hipCenter = CGPoint(
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2
        )
        
        // 计算身体朝向向量
        let bodyVector = CGPoint(
            x: shoulderCenter.x - hipCenter.x,
            y: shoulderCenter.y - hipCenter.y
        )
        
        return atan2(bodyVector.y, bodyVector.x)
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var normalized = angle
        while normalized > .pi { normalized -= 2 * .pi }
        while normalized < -.pi { normalized += 2 * .pi }
        return normalized
    }
    
    private func calculateAngleDifference(_ angle1: Double, _ angle2: Double) -> Double {
        let diff = angle1 - angle2
        return normalizeAngle(diff)
    }
    
    private func detectRotation() {
        guard shoulderAngles.count >= 5 else { return }
        
        let recentAngles = Array(shoulderAngles.suffix(5))
        let currentNormalizedAngle = recentAngles.last!.normalizedAngle
        
        // 计算累积角度变化
        var totalRotation: Double = 0
        var rotationDirection: RotationDirection = .none
        var directionConsistency = 0
        
        for i in 1..<recentAngles.count {
            let angleDiff = calculateAngleDifference(
                recentAngles[i].normalizedAngle,
                recentAngles[i-1].normalizedAngle
            )
            totalRotation += angleDiff
            
            // 确定旋转方向
            if abs(angleDiff) > rotationThreshold {
                if angleDiff > 0 {
                    if rotationDirection == .clockwise || rotationDirection == .none {
                        rotationDirection = .clockwise
                        directionConsistency += 1
                    } else {
                        directionConsistency -= 1
                    }
                } else {
                    if rotationDirection == .counterClockwise || rotationDirection == .none {
                        rotationDirection = .counterClockwise
                        directionConsistency += 1
                    } else {
                        directionConsistency -= 1
                    }
                }
            }
        }
        
        // 检查时间间隔
        let timeSinceLastRotation = Date().timeIntervalSince(lastRotationTime)
        let canRotate = timeSinceLastRotation >= minRotationInterval
        
        // 检查方向一致性
        let isConsistentDirection = directionConsistency >= 3
        
        // 只在检测到转圈时打印详细日志
        if abs(totalRotation) >= fullRotationThreshold && isConsistentDirection {
            print("DEBUG: RotationDetector - Potential rotation: total=\(String(format: "%.3f", totalRotation)) rad, direction=\(rotationDirection), canRotate=\(canRotate)")
        }
        
        // 检测完整转圈
        if !isRotating && canRotate && abs(totalRotation) >= fullRotationThreshold && isConsistentDirection {
            // 开始转圈
            rotationCount += 1
            isRotating = true
            lastRotationTime = Date()
            self.rotationDirection = rotationDirection
            currentAngle = totalRotation
            
            print("✅ RotationDetector - Rotation detected! Count: \(rotationCount), Direction: \(rotationDirection)")
            
            // 更新UI
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } else if isRotating && abs(totalRotation) < 0.5 {
            // 转圈结束
            isRotating = false
            self.rotationDirection = .none
            print("DEBUG: RotationDetector - Rotation ended")
            
            // 更新UI
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        // 更新当前角度
        self.currentAngle = totalRotation
    }
    
    func reset() {
        rotationCount = 0
        isRotating = false
        currentAngle = 0.0
        rotationDirection = .none
        shoulderAngles.removeAll()
        bodyOrientations.removeAll()
        rotationStates.removeAll()
        lastRotationTime = Date()
        print("DEBUG: RotationDetector - Reset")
    }
}

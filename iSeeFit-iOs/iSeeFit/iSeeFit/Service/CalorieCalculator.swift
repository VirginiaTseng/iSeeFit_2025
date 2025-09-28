//
//  CalorieCalculator.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-20.
//

import Foundation
import SwiftUI

class CalorieCalculator: ObservableObject {
    @Published var totalCalories: Double = 0.0
    @Published var currentRate: Double = 0.0  // 卡路里/分钟
    @Published var sessionDuration: TimeInterval = 0.0
    @Published var averageIntensity: Double = 0.0
    
    // 用户信息
    private var userWeight: Double = 70.0  // 默认体重(kg)
    private var userHeight: Double = 170.0  // 默认身高(cm)
    private var userAge: Int = 30  // 默认年龄
    
    // 计算参数
    private var lastUpdateTime: Date = Date()
    private var sessionStartTime: Date = Date()
    private var intensityHistory: [Double] = []
    
    // MET值表 (代谢当量)
    private let metValues: [String: Double] = [
        "jumping": 8.0,      // 跳跃
        "rotating": 6.0,     // 转圈
        "squats": 5.0,       // 深蹲
        "walking": 3.5,      // 走路
        "standing": 1.0,     // 站立
        "idle": 1.0          // 静止
    ]
    
    init() {
        print("DEBUG: CalorieCalculator - Initialized")
        loadUserProfile()
    }
    
    private func loadUserProfile() {
        // 从UserDefaults加载用户信息
        userWeight = UserDefaults.standard.double(forKey: "userWeight")
        if userWeight == 0 { userWeight = 70.0 }  // 默认值
        
        userHeight = UserDefaults.standard.double(forKey: "userHeight")
        if userHeight == 0 { userHeight = 170.0 }  // 默认值
        
        userAge = UserDefaults.standard.integer(forKey: "userAge")
        if userAge == 0 { userAge = 30 }  // 默认值
        
        print("DEBUG: CalorieCalculator - User profile loaded: weight=\(userWeight)kg, height=\(userHeight)cm, age=\(userAge)")
    }
    
    func updateCalories(
        jumpCount: Int,
        rotationCount: Int,
        isActive: Bool,
        poseType: PoseType = .unknown
    ) {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastUpdateTime)
        sessionDuration = now.timeIntervalSince(sessionStartTime)
        
        // 计算当前活动强度
        let currentIntensity = calculateActivityIntensity(
            jumpCount: jumpCount,
            rotationCount: rotationCount,
            isActive: isActive,
            poseType: poseType
        )
        
        // 添加到强度历史
        intensityHistory.append(currentIntensity)
        if intensityHistory.count > 30 {  // 保持最近30个数据点
            intensityHistory.removeFirst()
        }
        
        // 计算平均强度
        averageIntensity = intensityHistory.reduce(0, +) / Double(intensityHistory.count)
        
        // 计算卡路里消耗率
        let calorieRate = calculateCalorieRate(intensity: currentIntensity)
        currentRate = calorieRate
        
        // 计算这段时间消耗的卡路里
        let caloriesThisInterval = calorieRate * (timeDelta / 60.0)
        totalCalories += caloriesThisInterval
        
        lastUpdateTime = now
        
        // 减少日志频率 - 每30次更新打印一次
        if intensityHistory.count % 30 == 0 {
            print("DEBUG: CalorieCalculator - Updated: intensity=\(String(format: "%.2f", currentIntensity)), rate=\(String(format: "%.1f", calorieRate)) cal/min, total=\(String(format: "%.1f", totalCalories)) cal")
        }
    }
    
    private func calculateActivityIntensity(
        jumpCount: Int,
        rotationCount: Int,
        isActive: Bool,
        poseType: PoseType
    ) -> Double {
        if !isActive {
            return 0.0
        }
        
        var intensity: Double = 0.0
        
        // 基于运动类型的基础强度
        switch poseType {
        case .squat:
            intensity = 0.6
        case .pushup:
            intensity = 0.7
        case .plank:
            intensity = 0.5
        case .standing:
            intensity = 0.2
        case .unknown:
            intensity = 0.3
        }
        
        // 基于运动频率调整强度
        let jumpIntensity = min(Double(jumpCount) / 20.0, 1.0)  // 每20次跳跃为满强度
        let rotationIntensity = min(Double(rotationCount) / 10.0, 1.0)  // 每10次转圈为满强度
        
        // 综合强度计算
        let frequencyIntensity = max(jumpIntensity, rotationIntensity)
        let finalIntensity = (intensity + frequencyIntensity) / 2.0
        
        return min(finalIntensity, 1.0)  // 限制在0-1范围内
    }
    
    private func calculateCalorieRate(intensity: Double) -> Double {
        // 基础代谢率 (BMR) - 使用Mifflin-St Jeor公式
        let bmr = calculateBMR()
        
        // 活动代谢率
        let activityMultiplier = 1.0 + (intensity * 7.0)  // 0-8倍基础代谢
        
        // 每分钟卡路里消耗
        let caloriesPerMinute = (bmr / 1440.0) * activityMultiplier  // 1440分钟/天
        
        return caloriesPerMinute
    }
    
    private func calculateBMR() -> Double {
        // Mifflin-St Jeor公式
        let weight = userWeight
        let height = userHeight
        let age = Double(userAge)
        
        // 使用通用公式 (假设男性，女性需要调整)
        let bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
        
        return max(bmr, 1200.0)  // 最小BMR
    }
    
    func getCalorieBreakdown() -> CalorieBreakdown {
        let durationInHours = sessionDuration / 3600.0
        let caloriesPerHour = totalCalories / max(durationInHours, 0.01)
        
        return CalorieBreakdown(
            totalCalories: totalCalories,
            currentRate: currentRate,
            averageRate: caloriesPerHour,
            sessionDuration: sessionDuration,
            averageIntensity: averageIntensity
        )
    }
    
    func reset() {
        totalCalories = 0.0
        currentRate = 0.0
        sessionDuration = 0.0
        averageIntensity = 0.0
        lastUpdateTime = Date()
        sessionStartTime = Date()
        intensityHistory.removeAll()
        print("DEBUG: CalorieCalculator - Reset")
    }
    
    func saveUserProfile(weight: Double, height: Double, age: Int) {
        userWeight = weight
        userHeight = height
        userAge = age
        
        UserDefaults.standard.set(weight, forKey: "userWeight")
        UserDefaults.standard.set(height, forKey: "userHeight")
        UserDefaults.standard.set(age, forKey: "userAge")
        
        print("DEBUG: CalorieCalculator - User profile saved: weight=\(weight)kg, height=\(height)cm, age=\(age)")
    }
}

struct CalorieBreakdown {
    let totalCalories: Double
    let currentRate: Double
    let averageRate: Double
    let sessionDuration: TimeInterval
    let averageIntensity: Double
}

//
//  WorkoutRecorder.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-20.
//

import Foundation
import SwiftUI

class WorkoutRecorder: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var currentWorkout: WorkoutSession?
    @Published var workoutHistory: [WorkoutSession] = []
    
    private let userDefaults = UserDefaults.standard
    private let workoutHistoryKey = "workoutHistory"
    
    init() {
        loadWorkoutHistory()
        print("DEBUG: WorkoutRecorder - Initialized, loaded \(workoutHistory.count) workouts")
    }
    
    func startWorkout(workoutType: String) {
        let workout = WorkoutSession(
            id: UUID(),
            workoutType: workoutType,
            startTime: Date(),
            endTime: nil,
            jumpCount: 0,
            rotationCount: 0,
            caloriesBurned: 0.0,
            averageIntensity: 0.0,
            duration: 0.0
        )
        
        currentWorkout = workout
        isRecording = true
        
        print("DEBUG: WorkoutRecorder - Started workout: \(workoutType)")
    }
    
    func updateWorkout(
        jumpCount: Int,
        rotationCount: Int,
        caloriesBurned: Double,
        averageIntensity: Double
    ) {
        guard var workout = currentWorkout else { return }
        
        workout.jumpCount = jumpCount
        workout.rotationCount = rotationCount
        workout.caloriesBurned = caloriesBurned
        workout.averageIntensity = averageIntensity
        workout.duration = Date().timeIntervalSince(workout.startTime)
        
        currentWorkout = workout
        
        print("DEBUG: WorkoutRecorder - Updated workout:")
        print("  - Jumps: \(jumpCount)")
        print("  - Rotations: \(rotationCount)")
        print("  - Calories: \(String(format: "%.2f", caloriesBurned))")
        print("  - Duration: \(String(format: "%.1f", workout.duration))s")
    }
    
    func endWorkout() {
        guard var workout = currentWorkout else { return }
        
        workout.endTime = Date()
        workout.duration = workout.endTime!.timeIntervalSince(workout.startTime)
        
        // 添加到历史记录
        workoutHistory.append(workout)
        
        // 保存到本地存储
        saveWorkoutHistory()
        
        print("DEBUG: WorkoutRecorder - Ended workout:")
        print("  - Type: \(workout.workoutType)")
        print("  - Duration: \(String(format: "%.1f", workout.duration))s")
        print("  - Jumps: \(workout.jumpCount)")
        print("  - Rotations: \(workout.rotationCount)")
        print("  - Calories: \(String(format: "%.2f", workout.caloriesBurned))")
        
        // 重置当前训练
        currentWorkout = nil
        isRecording = false
    }
    
    func cancelWorkout() {
        currentWorkout = nil
        isRecording = false
        print("DEBUG: WorkoutRecorder - Cancelled workout")
    }
    
    private func saveWorkoutHistory() {
        do {
            let data = try JSONEncoder().encode(workoutHistory)
            userDefaults.set(data, forKey: workoutHistoryKey)
            print("DEBUG: WorkoutRecorder - Saved \(workoutHistory.count) workouts to UserDefaults")
        } catch {
            print("ERROR: WorkoutRecorder - Failed to save workout history: \(error)")
        }
    }
    
    private func loadWorkoutHistory() {
        guard let data = userDefaults.data(forKey: workoutHistoryKey) else {
            print("DEBUG: WorkoutRecorder - No workout history found")
            return
        }
        
        do {
            workoutHistory = try JSONDecoder().decode([WorkoutSession].self, from: data)
            print("DEBUG: WorkoutRecorder - Loaded \(workoutHistory.count) workouts from UserDefaults")
        } catch {
            print("ERROR: WorkoutRecorder - Failed to load workout history: \(error)")
            workoutHistory = []
        }
    }
    
    func getWorkoutStatistics() -> WorkoutStatistics {
        let totalWorkouts = workoutHistory.count
        let totalDuration = workoutHistory.reduce(0) { $0 + $1.duration }
        let totalCalories = workoutHistory.reduce(0) { $0 + $1.caloriesBurned }
        let totalJumps = workoutHistory.reduce(0) { $0 + $1.jumpCount }
        let totalRotations = workoutHistory.reduce(0) { $0 + $1.rotationCount }
        
        let averageDuration = totalWorkouts > 0 ? totalDuration / Double(totalWorkouts) : 0
        let averageCalories = totalWorkouts > 0 ? totalCalories / Double(totalWorkouts) : 0
        
        return WorkoutStatistics(
            totalWorkouts: totalWorkouts,
            totalDuration: totalDuration,
            totalCalories: totalCalories,
            totalJumps: totalJumps,
            totalRotations: totalRotations,
            averageDuration: averageDuration,
            averageCalories: averageCalories
        )
    }
    
    func clearHistory() {
        workoutHistory.removeAll()
        userDefaults.removeObject(forKey: workoutHistoryKey)
        print("DEBUG: WorkoutRecorder - Cleared workout history")
    }
}

struct WorkoutSession: Codable, Identifiable, Equatable {
    let id: UUID
    let workoutType: String  // 改为 String 类型
    let startTime: Date
    var endTime: Date?
    var jumpCount: Int
    var rotationCount: Int
    var caloriesBurned: Double
    var averageIntensity: Double
    var duration: TimeInterval
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}

struct WorkoutStatistics {
    let totalWorkouts: Int
    let totalDuration: TimeInterval
    let totalCalories: Double
    let totalJumps: Int
    let totalRotations: Int
    let averageDuration: TimeInterval
    let averageCalories: Double
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    var formattedAverageDuration: String {
        let minutes = Int(averageDuration) / 60
        let seconds = Int(averageDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

import Foundation
import SwiftUI

// MARK: - Daily Record Data Model
struct DailyRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    var meals: [MealRecord] // Array of meal records for the day
    var workouts: [WorkoutRecord] // Array of workout records for the day
    var totalCaloriesIntake: Int // Total calories consumed today
    var totalCaloriesBurned: Int // Total calories burned today
    
    // Calculated property for net calories (intake - burned)
    var netCalories: Int {
        totalCaloriesIntake - totalCaloriesBurned
    }
    
    // Initialize daily record with current date or specified date
    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.meals = []
        self.workouts = []
        self.totalCaloriesIntake = 0
        self.totalCaloriesBurned = 0
        
        // Debug log for record initialization
        print("DEBUG: Initialized DailyRecord for date: \(date)")
    }
}

// MARK: - Meal Record
struct MealRecord: Identifiable, Codable {
    let id: UUID
    let timestamp: Date // When the meal was recorded
    let mealType: MealType // Type of meal (breakfast, lunch, etc.)
    var foodItems: [FoodItem] // List of food items in this meal
    var totalCalories: Int // Total calories for this meal
    let imagePath: String? // Path to compressed image
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
    }
    
    // Initialize meal record
    init(timestamp: Date, mealType: MealType, foodItems: [FoodItem], totalCalories: Int, imagePath: String?) {
        self.id = UUID()
        self.timestamp = timestamp
        self.mealType = mealType
        self.foodItems = foodItems
        self.totalCalories = totalCalories
        self.imagePath = imagePath
    }
}



// MARK: - Workout Record
struct WorkoutRecord: Identifiable, Codable {
    let id: UUID // Unique identifier
    let timestamp: Date // When the workout was recorded
    let workoutType: String // Type of workout
    let duration: Int // Duration in minutes
    let caloriesBurned: Int // Calories burned during workout
    let repCount: Int? // Number of repetitions (optional)
    let imagePath: String? // Path to compressed image
    
    // Initialize workout record
    init(timestamp: Date, workoutType: String, duration: Int, caloriesBurned: Int, repCount: Int?, imagePath: String?) {
        self.id = UUID()
        self.timestamp = timestamp
        self.workoutType = workoutType
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.repCount = repCount
        self.imagePath = imagePath
    }
}

// MARK: - Image Compression Utility
class ImageCompressor {
    // Compress and save image to documents directory
    // Note: This is a placeholder implementation for SwiftUI
    // In a real implementation, you would need to convert SwiftUI Image to Data
    static func compressAndSave(_ image: Image, filename: String) -> String? {
        // Debug log for image compression start
        print("DEBUG: Starting image compression for filename: \(filename)")
        
        // TODO: Implement actual image compression for SwiftUI Image
        // This would require converting SwiftUI Image to Data
        print("WARNING: Image compression not fully implemented for SwiftUI Image")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesPath = documentsPath.appendingPathComponent("Images")
        
        // Create Images directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
            print("DEBUG: Created Images directory at: \(imagesPath.path)")
        } catch {
            print("WARNING: Failed to create Images directory: \(error)")
        }
        
        let fileURL = imagesPath.appendingPathComponent("\(filename).jpg")
        
        // For now, just return the path without actual compression
        print("DEBUG: Would save image to: \(fileURL.path)")
        return fileURL.path
    }
    
    // Load image from file path
    static func loadImage(from path: String) -> Image? {
        print("DEBUG: Attempting to load image from path: \(path)")
        // TODO: Implement actual image loading for SwiftUI
        print("WARNING: Image loading not fully implemented for SwiftUI Image")
        return nil
    }
}

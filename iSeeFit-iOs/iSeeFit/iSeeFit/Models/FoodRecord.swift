//
//  FoodRecord.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-25.
//

import Foundation
import SwiftUI

// MARK: - Food Record Data Model
struct FoodRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let mealType: String // breakfast, lunch, dinner, snack
    let foodName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let portionSize: String?
    let notes: String?
    let imagePath: String? // Local path to saved image
    let analysisMode: String // openai_generative or food101_classifier
    let detectedFoods: [DetectedFoodItem] // Detailed analysis results
    
    // Initialize food record
    init(
        mealType: String,
        foodName: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        portionSize: String? = nil,
        notes: String? = nil,
        imagePath: String? = nil,
        analysisMode: String = "unknown",
        detectedFoods: [DetectedFoodItem] = [],
        date: Date = Date()
    ) {
        self.id = UUID()
        self.date = date
        self.mealType = mealType
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.portionSize = portionSize
        self.notes = notes
        self.imagePath = imagePath
        self.analysisMode = analysisMode
        self.detectedFoods = detectedFoods
        
        // Debug log for food record initialization
        print("DEBUG: Initialized FoodRecord - \(mealType): \(foodName), \(calories)kcal @ \(date)")
    }
}

// MARK: - Detected Food Item
struct DetectedFoodItem: Identifiable, Codable, Equatable {
    let id: UUID
    let foodName: String
    let portionGrams: Double
    let confidence: Double
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let source: String // built_in or fallback
    
    init(
        foodName: String,
        portionGrams: Double,
        confidence: Double,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        source: String
    ) {
        self.id = UUID()
        self.foodName = foodName
        self.portionGrams = portionGrams
        self.confidence = confidence
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.source = source
    }
}

// MARK: - Food Statistics
struct FoodStatistics {
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let mealCount: Int
    let averageCaloriesPerMeal: Double
    let mostCommonMealType: String
    let dateRange: DateInterval?
    
    init(records: [FoodRecord]) {
        guard !records.isEmpty else {
            self.totalCalories = 0
            self.totalProtein = 0
            self.totalCarbs = 0
            self.totalFat = 0
            self.mealCount = 0
            self.averageCaloriesPerMeal = 0
            self.mostCommonMealType = "none"
            self.dateRange = nil
            return
        }
        
        self.totalCalories = records.reduce(0) { $0 + $1.calories }
        self.totalProtein = records.reduce(0) { $0 + $1.protein }
        self.totalCarbs = records.reduce(0) { $0 + $1.carbs }
        self.totalFat = records.reduce(0) { $0 + $1.fat }
        self.mealCount = records.count
        self.averageCaloriesPerMeal = totalCalories / Double(mealCount)
        
        // Find most common meal type
        let mealTypeCounts = Dictionary(grouping: records, by: { $0.mealType })
            .mapValues { $0.count }
        self.mostCommonMealType = mealTypeCounts.max(by: { $0.value < $1.value })?.key ?? "none"
        
        // Calculate date range
        let dates = records.map { $0.date }
        if let minDate = dates.min(), let maxDate = dates.max() {
            self.dateRange = DateInterval(start: minDate, end: maxDate)
        } else {
            self.dateRange = nil
        }
        
        print("DEBUG: Food Statistics calculated - Total: \(totalCalories)kcal, Meals: \(mealCount), Avg: \(String(format: "%.1f", averageCaloriesPerMeal))kcal")
    }
}

// MARK: - Meal Type
enum MealType: String, CaseIterable, Codable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    
    var displayName: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        case .snack:
            return "Snack"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast:
            return "sunrise"
        case .lunch:
            return "sun.max"
        case .dinner:
            return "sunset"
        case .snack:
            return "leaf"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast:
            return .orange
        case .lunch:
            return .yellow
        case .dinner:
            return .blue
        case .snack:
            return .green
        }
    }
}

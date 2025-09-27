//
//  WeightRecord.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-19.
//

import Foundation
import SwiftUI

// MARK: - Weight Record Data Model
struct WeightRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weight: Double // Weight in kg
    let notes: String? // Optional notes about the weight entry
    let imagePath: String? // Optional photo of scale reading
    
    // Initialize weight record
    init(weight: Double, date: Date = Date(), notes: String? = nil, imagePath: String? = nil) {
        self.id = UUID()
        self.weight = weight
        self.date = date
        self.notes = notes
        self.imagePath = imagePath
        
        // Debug log for weight record initialization
        print("DEBUG: Initialized WeightRecord - Weight: \(weight)kg, Date: \(date)")
    }
}

// MARK: - BMI Calculation
struct BMICalculator {
    static func calculate(weight: Double, height: Double) -> Double {
        guard height > 0 else { return 0 }
        let heightInMeters = height / 100.0 // Convert cm to meters
        let bmi = weight / (heightInMeters * heightInMeters)
        
        print("DEBUG: BMI Calculation - Weight: \(weight)kg, Height: \(height)cm, BMI: \(String(format: "%.1f", bmi))")
        return bmi
    }
    
    static func getBMICategory(_ bmi: Double) -> BMICategory {
        switch bmi {
        case 0..<18.5:
            return .underweight
        case 18.5..<25:
            return .normal
        case 25..<30:
            return .overweight
        default:
            return .obese
        }
    }
    
    static func getBMIColor(_ bmi: Double) -> Color {
        let category = getBMICategory(bmi)
        switch category {
        case .underweight:
            return .blue
        case .normal:
            return .green
        case .overweight:
            return .orange
        case .obese:
            return .red
        }
    }
}

// MARK: - BMI Category
enum BMICategory: String, CaseIterable, Codable {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"
    
    var description: String {
        switch self {
        case .underweight:
            return "Underweight (BMI < 18.5)"
        case .normal:
            return "Normal (BMI 18.5-24.9)"
        case .overweight:
            return "Overweight (BMI 25-29.9)"
        case .obese:
            return "Obese (BMI ≥ 30)"
        }
    }
    
    var color: Color {
        switch self {
        case .underweight:
            return .blue
        case .normal:
            return .green
        case .overweight:
            return .orange
        case .obese:
            return .red
        }
    }
}

// MARK: - Weight Statistics
struct WeightStatistics {
    let currentWeight: Double
    let previousWeight: Double?
    let weightChange: Double
    let weightChangePercentage: Double
    let averageWeight: Double
    let minWeight: Double
    let maxWeight: Double
    let recordCount: Int
    let bmi: Double
    let bmiCategory: BMICategory
    
    init(records: [WeightRecord], height: Double) {
        guard !records.isEmpty else {
            self.currentWeight = 0
            self.previousWeight = nil
            self.weightChange = 0
            self.weightChangePercentage = 0
            self.averageWeight = 0
            self.minWeight = 0
            self.maxWeight = 0
            self.recordCount = 0
            self.bmi = 0
            self.bmiCategory = .normal
            return
        }
        
        let sortedRecords = records.sorted { $0.date > $1.date }
        self.currentWeight = sortedRecords.first?.weight ?? 0
        self.previousWeight = sortedRecords.count > 1 ? sortedRecords[1].weight : nil
        
        if let previous = previousWeight {
            self.weightChange = currentWeight - previous
            self.weightChangePercentage = (weightChange / previous) * 100
        } else {
            self.weightChange = 0
            self.weightChangePercentage = 0
        }
        
        let weights = records.map { $0.weight }
        self.averageWeight = weights.reduce(0, +) / Double(weights.count)
        self.minWeight = weights.min() ?? 0
        self.maxWeight = weights.max() ?? 0
        self.recordCount = records.count
        
        self.bmi = BMICalculator.calculate(weight: currentWeight, height: height)
        self.bmiCategory = BMICalculator.getBMICategory(self.bmi)
        
        print("DEBUG: Weight Statistics calculated - Current: \(currentWeight)kg, Change: \(weightChange)kg, BMI: \(String(format: "%.1f", bmi))")
    }
}




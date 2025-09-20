//
//  FoodItem.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//
import Foundation

struct FoodItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let confidence: Double
}

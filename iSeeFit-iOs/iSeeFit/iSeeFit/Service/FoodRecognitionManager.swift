//
//  FoodRecognitionManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import Foundation
import Vision
import UIKit

class FoodRecognitionManager: ObservableObject {
    struct FoodItem: Identifiable {
        let id = UUID()
        let name: String
        let confidence: Double
        let calories: Int
    }

    @Published var items: [FoodItem] = []
    @Published var totalCalories: Int = 0
    @Published var errorMessage: String?

    func analyze(image: UIImage) {
        items.removeAll()
        totalCalories = 0
        errorMessage = nil

        guard let cgImage = image.cgImage else { return }

        // Use built-in image classification (or replace with a food-specific CoreML model)
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
                return
            }
            let observations = (request.results as? [VNClassificationObservation]) ?? []
            // 先按置信度筛选，然后排除常见“非食物”类目
            let top = observations
                .prefix(10)
                .filter { $0.confidence > 0.2 }
                .filter { self.isFoodCategory($0.identifier) }

            var recognized: [FoodItem] = []
            var total = 0
            for c in top {
                let name = c.identifier
                let calories = self.estimateCalories(for: name)
                total += calories
                recognized.append(FoodItem(name: name, confidence: Double(c.confidence), calories: calories))
            }

            DispatchQueue.main.async {
                self.items = recognized
                self.totalCalories = total
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async { self.errorMessage = "Failed to analyze image." }
            }
        }
    }

    // 仅保留食物相关类目，排除常见餐具/容器/饮品容器等
    private func isFoodCategory(_ label: String) -> Bool {
        let name = label.lowercased()

        // 明确排除项（非食物）
        let nonFoodKeywords: [String] = [
            "tableware", "utensil", "plate", "drinking glass", "glass",
            "bottle", "cup", "mug", "teapot", "kettle", "pitcher",
            "fork", "knife", "spoon", "chopstick", "tray", "napkin",
            "table", "countertop", "cutting board", "saucepan", "skillet",
            "pan", "pot", "bowl", "jar", "can"
        ]
        if nonFoodKeywords.contains(where: { name.contains($0) }) { return false }

        // 允许项（常见食物关键字）
        let foodKeywords: [String] = [
            "food", "dish", "meal", "cuisine",
            "pizza", "burger", "sandwich", "salad", "sushi", "noodle", "pasta",
            "rice", "steak", "chicken", "beef", "pork", "tofu", "fish",
            "fries", "chips", "cake", "dessert", "bread", "soup", "dumpling",
            "egg", "omelette", "taco", "burrito", "shawarma", "kebab", "noodles"
        ]

        // 若包含食物关键字则判定为食物
        if foodKeywords.contains(where: { name.contains($0) }) { return true }

        // 对于模型返回较泛的标签，若看起来像“drink”也可排除以免估卡路里（可根据需要调整）
        let drinkKeywords = ["drink", "beverage", "coffee", "tea", "juice", "soda"]
        if drinkKeywords.contains(where: { name.contains($0) }) { return false }

        // 默认保守：不在明确食物列表中则排除，避免误给卡路里
        return false
    }

    private func estimateCalories(for foodName: String) -> Int {
        let key = foodName.lowercased()
        switch key {
        case let s where s.contains("pizza"): return 285
        case let s where s.contains("burger"): return 354
        case let s where s.contains("salad"): return 150
        case let s where s.contains("sushi"): return 200
        case let s where s.contains("noodle"): return 190
        case let s where s.contains("rice"): return 206
        case let s where s.contains("steak"): return 271
        case let s where s.contains("fries") || s.contains("chips"): return 312
        case let s where s.contains("cake") || s.contains("dessert"): return 239
        default: return 180
        }
    }
}



//
//  FoodRecognitionManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import Foundation
import Vision
import CoreML
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

        // cgImage 校验由 perform(image:requests:) 内部处理

        // Prefer CoreML food-specific model if available in bundle, else fallback to VNClassifyImageRequest
        if let mlModel = loadFoodModel() {
            let request = VNCoreMLRequest(model: mlModel) { [weak self] request, error in
                self?.handleClassifications(request: request, error: error)
            }
            perform(image: image, requests: [request])
            return
        }

        // Fallback: built-in image classification
        let request = VNClassifyImageRequest { [weak self] request, error in
            self?.handleClassifications(request: request, error: error)
        }
        perform(image: image, requests: [request])
    }

    private func perform(image: UIImage, requests: [VNRequest]) {
        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform(requests) }
            catch { DispatchQueue.main.async { self.errorMessage = "Failed to analyze image." } }
        }
    }

    private func handleClassifications(request: VNRequest, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription }
            return
        }
        let observations = (request.results as? [VNClassificationObservation]) ?? []
        let top = observations
            .prefix(10)
            .filter { $0.confidence > 0.2 }
            .filter { self.isFoodCategory($0.identifier) }

        var recognized: [FoodItem] = []
        var total = 0
        let group = DispatchGroup()

        // 去重：按标准化key避免“burrito/bean burrito”等重复累计
        var seenKeys = Set<String>()

        // 如果 Vision 结果为空，则触发 Qwen 兜底请求（例如中餐多菜时）
        if top.isEmpty {
#if DEBUG
            print("[Food] Vision returned no food candidates, fallback to Qwen hybrid…")
#endif
            group.enter()
            NutritionService.shared.fetchHybrid(foodCandidates: ["food"], context: "multi Chinese dishes on table") { info in
                if let info = info, let name = info.normalizedName, !name.isEmpty {
                    let key = self.canonicalKey(for: name)
                    if !seenKeys.contains(key) {
                        seenKeys.insert(key)
                        let calories = Int(info.caloriesPerServing.rounded())
                        recognized.append(FoodItem(name: name, confidence: 0.5, calories: calories))
                        total += calories
                    }
                }
                group.leave()
            }
        }

        for c in top {
            let name = c.identifier
            let key = canonicalKey(for: name)
            if seenKeys.contains(key) { continue }
            seenKeys.insert(key)
            var calories = self.estimateCalories(for: name)

            group.enter()
            // 先尝试混合模式(Qwen -> Edamam)，可回退
            NutritionService.shared.fetchHybrid(foodCandidates: [name], context: nil) { info in
                if let info = info {
                    // 若Qwen给了normalizedName，用其作为展示名称与去重基准
                    let displayName = info.normalizedName?.isEmpty == false ? info.normalizedName! : name
                    calories = Int(info.caloriesPerServing.rounded())
                    recognized.append(FoodItem(name: displayName, confidence: Double(c.confidence), calories: calories))
                } else {
                    recognized.append(FoodItem(name: name, confidence: Double(c.confidence), calories: calories))
                }
                total += calories
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.items = recognized.sorted { $0.confidence > $1.confidence }
            self.totalCalories = total
        }
    }

    // 生成用于去重的标准化key：小写、去标点、简单去复数
    private func canonicalKey(for raw: String) -> String {
        let lower = raw.lowercased()
        let alnum = lower.replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
        var token = alnum.trimmingCharacters(in: .whitespacesAndNewlines)
        if token.hasSuffix("es") { token = String(token.dropLast(2)) }
        else if token.hasSuffix("s") { token = String(token.dropLast(1)) }
        token = token.replacingOccurrences(of: "  ", with: " ")
        return token
    }

    private func loadFoodModel() -> VNCoreMLModel? {
        // Expect a compiled CoreML model named Food101.mlmodelc inside the bundle if provided
        if let url = Bundle.main.url(forResource: "Food101", withExtension: "mlmodelc"),
           let model = try? MLModel(contentsOf: url),
           let vnModel = try? VNCoreMLModel(for: model) {
            return vnModel
        }
        return nil
    }
        // 仅保留食物相关类目，排除常见餐具/容器/饮品容器等；同时排除过于泛化的词
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

        // 排除泛化词（仅当标签完全等于泛化词时排除；包含具体食物词时允许）
        let genericKeywords: Set<String> = ["food", "dish", "meal", "cuisine"]
        if genericKeywords.contains(name) { return false }

        // 允许项（常见食物关键字）
        let foodKeywords: [String] = [
            "food", "dish", "meal", "cuisine",
            "pizza", "burger", "sandwich", "salad", "sushi", "noodle", "pasta",
            "rice", "steak", "chicken", "beef", "pork", "tofu", "fish",
            "fries", "chips", "cake", "dessert", "bread", "soup", "dumpling",
            "egg", "omelette", "taco", "burrito", "shawarma", "kebab", "noodles"
        ]

        // 若包含明确食物关键字则判定为食物（泛化词已在上面排除）
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



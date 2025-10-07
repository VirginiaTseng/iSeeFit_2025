//
//  OpenAIService.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - OpenAI Response Models (与 Python 后端一致)
struct OpenAIFoodDetection: Codable {
    let items: [OpenAIFoodItem]
    let notes: String
}

struct OpenAIFoodItem: Codable {
    let name: String
    let grams: Double
    let confidence: Double
}

// MARK: - Nutrition Database (与 Python 后端一致)
struct NutritionPer100g {
    let kcal: Double
    let protein_g: Double
    let carb_g: Double
    let fat_g: Double
}

// 营养数据库 - 与 Python 后端完全一致
private let NUTRITION_DATABASE: [String: NutritionPer100g] = [
    // Fruits
    "apple": NutritionPer100g(kcal: 52, protein_g: 0.3, carb_g: 14.0, fat_g: 0.2),
    "banana": NutritionPer100g(kcal: 96, protein_g: 1.3, carb_g: 27.0, fat_g: 0.3),
    "orange": NutritionPer100g(kcal: 47, protein_g: 0.9, carb_g: 12.0, fat_g: 0.1),
    
    // Staples / dishes
    "white rice": NutritionPer100g(kcal: 130, protein_g: 2.4, carb_g: 28.0, fat_g: 0.3),
    "brown rice": NutritionPer100g(kcal: 111, protein_g: 2.6, carb_g: 23.0, fat_g: 0.9),
    "pasta": NutritionPer100g(kcal: 131, protein_g: 5.0, carb_g: 25.0, fat_g: 1.1),
    "bread": NutritionPer100g(kcal: 265, protein_g: 9.0, carb_g: 49.0, fat_g: 3.2),
    "hamburger": NutritionPer100g(kcal: 295, protein_g: 17.0, carb_g: 30.0, fat_g: 12.0),
    "pizza": NutritionPer100g(kcal: 266, protein_g: 11.0, carb_g: 33.0, fat_g: 10.0),
    
    // Proteins
    "chicken": NutritionPer100g(kcal: 165, protein_g: 31.0, carb_g: 0.0, fat_g: 3.6),
    "beef": NutritionPer100g(kcal: 250, protein_g: 26.0, carb_g: 0.0, fat_g: 15.0),
    "fish": NutritionPer100g(kcal: 200, protein_g: 22.0, carb_g: 0.0, fat_g: 12.0),
    "eggs": NutritionPer100g(kcal: 155, protein_g: 13.0, carb_g: 1.1, fat_g: 11.0),
    
    // Vegetables
    "carrots": NutritionPer100g(kcal: 41, protein_g: 0.9, carb_g: 10.0, fat_g: 0.2),
    "broccoli": NutritionPer100g(kcal: 34, protein_g: 2.8, carb_g: 7.0, fat_g: 0.4),
    "potatoes": NutritionPer100g(kcal: 77, protein_g: 2.0, carb_g: 17.0, fat_g: 0.1),
    "french fries": NutritionPer100g(kcal: 365, protein_g: 4.0, carb_g: 63.0, fat_g: 11.0),
    
    // Dairy
    "cheese": NutritionPer100g(kcal: 350, protein_g: 25.0, carb_g: 1.0, fat_g: 28.0),
    "milk": NutritionPer100g(kcal: 42, protein_g: 3.4, carb_g: 5.0, fat_g: 1.0),
    
    // Others
    "peas": NutritionPer100g(kcal: 81, protein_g: 5.4, carb_g: 14.0, fat_g: 0.4),
    "shrimp": NutritionPer100g(kcal: 99, protein_g: 24.0, carb_g: 0.0, fat_g: 0.3)
]


struct OpenAIChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - OpenAI Service
final class OpenAIService {
    static let shared = OpenAIService()
    
    private init() {
        print("DEBUG: OpenAIService - Initialized")
    }
    
    // MARK: - Helper Methods
    private func extractJSONFromContent(_ content: String) -> String {
        print("DEBUG: OpenAIService - Raw content: \(content)")
        
        // 查找 JSON 开始位置
        let jsonStartPatterns = ["```json", "```", "{"]
        var jsonStartIndex: String.Index?
        
        for pattern in jsonStartPatterns {
            if let range = content.range(of: pattern) {
                jsonStartIndex = range.upperBound
                break
            }
        }
        
        guard let startIndex = jsonStartIndex else {
            print("ERROR: OpenAIService - No JSON start pattern found")
            return content
        }
        
        // 查找 JSON 结束位置
        var jsonEndIndex: String.Index?
        let jsonEndPatterns = ["```", "}"]
        
        for pattern in jsonEndPatterns {
            if let range = content.range(of: pattern, options: .backwards, range: startIndex..<content.endIndex) {
                jsonEndIndex = range.lowerBound
                break
            }
        }
        
        guard let endIndex = jsonEndIndex else {
            print("ERROR: OpenAIService - No JSON end pattern found")
            return content
        }
        
        let jsonContent = String(content[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        print("DEBUG: OpenAIService - Extracted JSON: \(jsonContent.prefix(200))...")
        
        return jsonContent
    }
    
    // MARK: - Public Methods
    func analyzeFoodWithOpenAI(image: UIImage) async throws -> FoodAnalysisResponse {
        print("DEBUG: OpenAIService - Starting OpenAI analysis (Python backend style)")
        
        // 第一步：识别食物和份量（与 Python 后端一致）
        let detection = try await detectFoodsAndPortions(image: image)
        print("DEBUG: OpenAIService - Detected \(detection.items.count) items")
        
        // 第二步：使用营养数据库计算详细营养信息（与 Python 后端一致）
        let result = calculateNutritionFromDetection(detection: detection)
        
        print("DEBUG: OpenAIService - Analysis completed successfully")
        return result
    }
    
    // MARK: - Step 1: Food Detection (与 Python 后端一致)
    private func detectFoodsAndPortions(image: UIImage) async throws -> OpenAIFoodDetection {
        // 1. 转换图片为 base64
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片编码失败"])
        }
        let base64String = jpegData.base64EncodedString()
        print("DEBUG: OpenAIService - Image encoded to base64, size: \(base64String.count) chars")
        
        // 2. 获取 API Key（从 user_config.txt 文件）
        let apiKey = getOpenAIAPIKey()
        if apiKey.isEmpty {
            throw NSError(domain: "OpenAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "缺少 OpenAI API Key，请创建 user_config.txt 文件并配置 API Key"])
        }
        
        // 3. 构建请求（与 Python 后端完全一致）
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "temperature": 0.2,
            "response_format": ["type": "json_object"], // 强制 JSON
            "messages": [
                [
                    "role": "system",
                    "content": "You are a nutrition assistant. Identify up to 3 distinct GENERIC foods in the photo and estimate each portion size in grams. Prefer generic names like hamburger, french fries, roast chicken, roasted potatoes, peas, carrots. Respond as STRICT JSON ONLY: {\"items\":[{\"name\":\"string\",\"grams\":number,\"confidence\":0-1}],\"notes\":\"short helpful note\"}"
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Identify foods and estimate portions in grams."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64String)"
                            ]
                        ]
                    ]
                ]
            ]
        ]
        
        // 4. 发送请求
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw NSError(domain: "OpenAIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "无效的 API URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("DEBUG: OpenAIService - Sending detection request to OpenAI")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 5. 检查响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIService", code: -4, userInfo: [NSLocalizedDescriptionKey: "无效的 HTTP 响应"])
        }
        
        if !(200..<300).contains(httpResponse.statusCode) {
            let errorMessage = String(data: data, encoding: .utf8) ?? "OpenAI 请求失败"
            print("ERROR: OpenAIService - HTTP \(httpResponse.statusCode): \(errorMessage)")
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // 6. 解析响应
        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw NSError(domain: "OpenAIService", code: -5, userInfo: [NSLocalizedDescriptionKey: "OpenAI 返回空内容"])
        }
        
        print("DEBUG: OpenAIService - Raw detection response: \(content)")
        
        // 7. 解析检测结果
        let detection = try JSONDecoder().decode(OpenAIFoodDetection.self, from: Data(content.utf8))
        print("DEBUG: OpenAIService - Successfully parsed detection result")
        
        return detection
    }
    
    // MARK: - Step 2: Nutrition Calculation (与 Python 后端一致)
    private func calculateNutritionFromDetection(detection: OpenAIFoodDetection) -> FoodAnalysisResponse {
        var perItems: [FoodAnalysisItem] = []
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var totalPortion: Double = 0
        
        for item in detection.items {
            // 查找营养数据库
            let nutrition = findNutritionInDatabase(foodName: item.name)
            
            // 计算营养信息（与 Python 后端一致）
            let factor = item.grams / 100.0
            let calories = nutrition.kcal * factor
            let protein = nutrition.protein_g * factor
            let carbs = nutrition.carb_g * factor
            let fat = nutrition.fat_g * factor
            
            let analysisItem = FoodAnalysisItem(
                food_detected: item.name,
                portion_g: item.grams,
                confidence: item.confidence,
                calories_kcal: calories,
                protein_g: protein,
                carbs_g: carbs,
                fat_g: fat,
                source: "openai_direct"
            )
            
            perItems.append(analysisItem)
            totalCalories += calories
            totalProtein += protein
            totalCarbs += carbs
            totalFat += fat
            totalPortion += item.grams
        }
        
        let totals = FoodAnalysisTotals(
            portion_g: totalPortion,
            calories_kcal: totalCalories,
            protein_g: totalProtein,
            carbs_g: totalCarbs,
            fat_g: totalFat
        )
        
        return FoodAnalysisResponse(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            mode: "openai_direct",
            per_item: perItems,
            totals: totals,
            notes: detection.notes,
            debug: "OpenAI GPT-4o-mini + Nutrition Database",
            error: nil
        )
    }
    
    // MARK: - API Key Management (直接读取文件)
    private func getOpenAIAPIKey() -> String {
        return UserConfig.shared.getOpenAIAPIKey()
    }
    
    // MARK: - Nutrition Database Lookup (与 Python 后端一致)
    private func findNutritionInDatabase(foodName: String) -> NutritionPer100g {
        let normalizedName = foodName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 直接查找
        if let nutrition = NUTRITION_DATABASE[normalizedName] {
            return nutrition
        }
        
        // 模糊匹配
        for (key, nutrition) in NUTRITION_DATABASE {
            if normalizedName.contains(key) || key.contains(normalizedName) {
                return nutrition
            }
        }
        
        // 默认值（如果找不到）
        print("WARNING: OpenAIService - No nutrition data found for '\(foodName)', using default")
        return NutritionPer100g(kcal: 100, protein_g: 5.0, carb_g: 15.0, fat_g: 2.0)
    }
}

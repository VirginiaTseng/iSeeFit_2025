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

// MARK: - OpenAI Response Models
struct OpenAIFoodResult: Codable {
    let title: String
    let ingredients: [OpenAIIngredient]
    let totalCalories: Double
    let healthScore: Double
    
    struct OpenAIIngredient: Codable {
        let name: String
        let description: String
        let caloriesPerGram: Double
        let totalGrams: Double
        let totalCalories: Double
        let protein_g: Double
        let carbs_g: Double
        let fat_g: Double
    }
}

// MARK: - Shared Data Models (重新定义以避免依赖问题)
//struct FoodAnalysisItem: Codable {
//    let food_detected: String
//    let portion_g: Double
//    let confidence: Double
//    let calories_kcal: Double
//    let protein_g: Double
//    let carbs_g: Double
//    let fat_g: Double
//    let source: String
//}
//
//struct FoodAnalysisTotals: Codable {
//    let portion_g: Double
//    let calories_kcal: Double
//    let protein_g: Double
//    let carbs_g: Double
//    let fat_g: Double
//}
//
//struct FoodAnalysisResponse: Codable {
//    let timestamp: String
//    let mode: String
//    let per_item: [FoodAnalysisItem]
//    let totals: FoodAnalysisTotals
//    let notes: String?
//    let debug: String?
//    let error: String?
//}

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
        print("DEBUG: OpenAIService - Starting OpenAI analysis")
        
        // 1. 转换图片为 base64
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片编码失败"])
        }
        let base64String = jpegData.base64EncodedString()
        print("DEBUG: OpenAIService - Image encoded to base64, size: \(base64String.count) chars")
        
        // 2. 获取 API Key
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
        if apiKey.isEmpty {
            throw NSError(domain: "OpenAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "缺少 OPENAI_API_KEY，请在 Info.plist 中配置"])
        }
        print("DEBUG: OpenAIService - API Key found")
        
        // 3. 构建请求
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": """
                        You are an AI calories calculator. Analyze this food image and respond with ONLY a valid JSON object (no additional text or explanations).

                        Required JSON format:
                        {
                          "title": "string",
                          "ingredients": [
                            {
                              "name": "string",
                              "description": "string",
                              "caloriesPerGram": number,
                              "totalGrams": number,
                              "totalCalories": number,
                              "protein_g": number,
                              "carbs_g": number,
                              "fat_g": number
                            }
                          ],
                          "totalCalories": number,
                          "healthScore": number
                        }

                        Use standard nutrition values:
                        - Rice: 1.3 kcal/g, 0.024 protein, 0.28 carbs, 0.003 fat
                        - Chicken: 1.65 kcal/g, 0.31 protein, 0 carbs, 0.036 fat
                        - Vegetables: 0.25 kcal/g, 0.02 protein, 0.05 carbs, 0.002 fat
                        - Bread: 2.65 kcal/g, 0.09 protein, 0.49 carbs, 0.032 fat
                        - Potatoes: 0.77 kcal/g, 0.02 protein, 0.17 carbs, 0.001 fat
                        - Cheese: 3.5 kcal/g, 0.25 protein, 0.01 carbs, 0.28 fat

                        Respond with ONLY the JSON object, no other text.
                        """
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64String)"
                        ]
                    ]
                ]
            ]]
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
        
        print("DEBUG: OpenAIService - Sending request to OpenAI")
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
        
        print("DEBUG: OpenAIService - Received response from OpenAI")
        
        // 6. 解析响应
        let chatResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw NSError(domain: "OpenAIService", code: -5, userInfo: [NSLocalizedDescriptionKey: "OpenAI 返回空内容"])
        }
        
        print("DEBUG: OpenAIService - Parsing OpenAI content: \(content.prefix(200))...")
        
        // 7. 提取纯 JSON 内容（移除 ```json 包装）
        let cleanContent = extractJSONFromContent(content)
        print("DEBUG: OpenAIService - Cleaned content: \(cleanContent.prefix(200))...")
        
        // 8. 解析 JSON 内容
        let openAIResult = try JSONDecoder().decode(OpenAIFoodResult.self, from: Data(cleanContent.utf8))
        print("DEBUG: OpenAIService - Successfully parsed OpenAI result")
        
        // 8. 转换为 FoodAnalysisResponse 格式
        let perItems: [FoodAnalysisItem] = openAIResult.ingredients.map { ingredient in
            FoodAnalysisItem(
                food_detected: ingredient.name,
                portion_g: ingredient.totalGrams,
                confidence: 0.9, // OpenAI 结果置信度设为 0.9
                calories_kcal: ingredient.totalCalories,
                protein_g: ingredient.protein_g, // 使用 OpenAI 返回的营养信息
                carbs_g: ingredient.carbs_g,
                fat_g: ingredient.fat_g,
                source: "openai_direct" // 添加缺失的 source 参数
            )
        }
        
        let totals = FoodAnalysisTotals(
            portion_g: openAIResult.ingredients.reduce(0) { $0 + $1.totalGrams },
            calories_kcal: openAIResult.totalCalories,
            protein_g: openAIResult.ingredients.reduce(0) { $0 + $1.protein_g },
            carbs_g: openAIResult.ingredients.reduce(0) { $0 + $1.carbs_g },
            fat_g: openAIResult.ingredients.reduce(0) { $0 + $1.fat_g }
        )
        
        let result = FoodAnalysisResponse(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            mode: "openai_direct",
            per_item: perItems,
            totals: totals,
            notes: "OpenAI 直接分析结果",
            debug: "OpenAI GPT-4o-mini",
            error: nil
        )
        
        print("DEBUG: OpenAIService - Analysis completed successfully")
        return result
    }
}

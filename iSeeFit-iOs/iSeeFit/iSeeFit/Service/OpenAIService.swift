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
    }
}

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
                        You are an AI calories calculator. Analyze this food image and respond strictly with JSON:
                        {
                          "title": "string",
                          "ingredients": [
                            {
                              "name": "string",
                              "description": "string", 
                              "caloriesPerGram": number,
                              "totalGrams": number,
                              "totalCalories": number
                            }
                          ],
                          "totalCalories": number,
                          "healthScore": number
                        }
                        Be as accurate as possible with portion sizes and nutritional values.
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
        
        // 7. 解析 JSON 内容
        let openAIResult = try JSONDecoder().decode(OpenAIFoodResult.self, from: Data(content.utf8))
        print("DEBUG: OpenAIService - Successfully parsed OpenAI result")
        
        // 8. 转换为 FoodAnalysisResponse 格式
        let perItems: [FoodAnalysisItem] = openAIResult.ingredients.map { ingredient in
            FoodAnalysisItem(
                food_detected: ingredient.name,
                portion_g: ingredient.totalGrams,
                confidence: 0.9, // OpenAI 结果置信度设为 0.9
                calories_kcal: ingredient.totalCalories,
                protein_g: 0, // OpenAI 暂时不提供详细营养
                carbs_g: 0,
                fat_g: 0
            )
        }
        
        let totals = FoodAnalysisTotals(
            portion_g: openAIResult.ingredients.reduce(0) { $0 + $1.totalGrams },
            calories_kcal: openAIResult.totalCalories,
            protein_g: 0,
            carbs_g: 0,
            fat_g: 0
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
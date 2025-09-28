//
//  RecommendationService.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-25.
//

import Foundation

// MARK: - Recommendation Request Model
struct RecommendationRequest: Codable {
    let food_name: String  // 改为单个字符串
    let health_condition: String
    let prompt_style: String
    
    init(foodNames: [String], healthCondition: String = "stomach", promptStyle: String = "simple") {
        self.food_name = foodNames.first ?? ""  // 只取第一个食物名称
        self.health_condition = healthCondition
        self.prompt_style = promptStyle
    }
}

// MARK: - Recommendation Response Model
struct RecommendationResponse: Codable {
    let success: Bool
    let advice: String?
    let error: String?
    let message: String?
}

// MARK: - Recommendation Service
class RecommendationService: ObservableObject {
    static let shared = RecommendationService()
    
    private let baseURL = APIConfig.baseURL
    private let session = URLSession.shared
    
    private init() {
        print("DEBUG: RecommendationService - Initialized")
    }
    
    // 获取健康建议
    func getAdvice(foodNames: [String], healthCondition: String = "stomach", promptStyle: String = "professional") async -> String? {
        let request = RecommendationRequest(
            foodNames: foodNames,
            healthCondition: healthCondition,
            promptStyle: promptStyle
        )
        
        guard let url = URL(string: "\(baseURL)/recommendations/getadvice") else {
            print("ERROR: RecommendationService - Invalid URL")
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            print("DEBUG: RecommendationService - Sending request:")
            print("  - URL: \(url)")
            print("  - Method: POST")
            print("  - Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
            print("  - Body: \(String(data: jsonData, encoding: .utf8) ?? "Failed to encode")")
            print("  - Food names: \(foodNames)")
            print("  - Health condition: \(healthCondition)")
            print("  - Prompt style: \(promptStyle)")
            
            let (data, response) = try await session.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: RecommendationService - Response status: \(httpResponse.statusCode)")
                print("DEBUG: RecommendationService - Response headers: \(httpResponse.allHeaderFields)")
            }
            
            // 打印响应内容
            if let responseString = String(data: data, encoding: .utf8) {
                print("DEBUG: RecommendationService - Response body: \(responseString)")
            }
            
            let recommendationResponse = try JSONDecoder().decode(RecommendationResponse.self, from: data)
            
            if recommendationResponse.success {
                print("DEBUG: RecommendationService - Successfully received advice")
                return recommendationResponse.advice
            } else {
                print("ERROR: RecommendationService - API error: \(recommendationResponse.error ?? "Unknown error")")
                return nil
            }
            
        } catch {
            print("ERROR: RecommendationService - Request failed: \(error)")
            return nil
        }
    }
}

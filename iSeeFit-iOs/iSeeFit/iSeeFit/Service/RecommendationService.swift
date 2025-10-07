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
    
    // 使用 UserDefaults 记录上次用于获取推荐的数据“指纹”（最新食物/训练时间）
    private let lastFetchedFoodDateKey = "recommendation_last_food_date"
    private let lastFetchedWorkoutDateKey = "recommendation_last_workout_date"
    
    private init() {
        print("DEBUG: RecommendationService - Initialized")
    }
    
    // MARK: - 稀疏判定（仅当有新食物/训练出现时才触发）
    // 说明：
    // - latestFoodDate / latestWorkoutDate 为调用方传入的当日最新记录时间（可为 nil）。
    // - 若两者均为 nil，表示无数据，默认不触发。
    // - 只要其中任意一个时间晚于上次已获取的对应时间，即认为有新数据需要获取。
    func shouldFetchRecommendation(latestFoodDate: Date?, latestWorkoutDate: Date?) -> Bool {
        let defaults = UserDefaults.standard
        let lastFoodTime = defaults.object(forKey: lastFetchedFoodDateKey) as? Date
        let lastWorkoutTime = defaults.object(forKey: lastFetchedWorkoutDateKey) as? Date
        
        print("DEBUG: RecommendationService - shouldFetchRecommendation inputs:")
        print("  - latestFoodDate: \(latestFoodDate?.description ?? "nil")")
        print("  - latestWorkoutDate: \(latestWorkoutDate?.description ?? "nil")")
        print("  - lastFetchedFoodDate: \(lastFoodTime?.description ?? "nil")")
        print("  - lastFetchedWorkoutDate: \(lastWorkoutTime?.description ?? "nil")")
        
        // 若完全没有数据则不触发
        guard latestFoodDate != nil || latestWorkoutDate != nil else {
            print("DEBUG: RecommendationService - No latest data, skip fetch")
            return false
        }
        
        // 只要任一方向有更新就应该触发
        if let lf = latestFoodDate, let lastF = lastFoodTime {
            if lf > lastF { return true }
        } else if latestFoodDate != nil && lastFoodTime == nil {
            return true
        }
        
        if let lw = latestWorkoutDate, let lastW = lastWorkoutTime {
            if lw > lastW { return true }
        } else if latestWorkoutDate != nil && lastWorkoutTime == nil {
            return true
        }
        
        print("DEBUG: RecommendationService - No new data since last fetch, skip")
        return false
    }
    
    // 在成功获取推荐后，更新“指纹”
    func markFetched(latestFoodDate: Date?, latestWorkoutDate: Date?) {
        let defaults = UserDefaults.standard
        if let lf = latestFoodDate {
            defaults.set(lf, forKey: lastFetchedFoodDateKey)
            print("DEBUG: RecommendationService - markFetched set last food date: \(lf)")
        }
        if let lw = latestWorkoutDate {
            defaults.set(lw, forKey: lastFetchedWorkoutDateKey)
            print("DEBUG: RecommendationService - markFetched set last workout date: \(lw)")
        }
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

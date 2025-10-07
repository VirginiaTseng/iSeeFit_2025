//
//  APIService.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-19.
//

import Foundation
import UIKit

// MARK: - API Configuration
struct APIConfig {
    static let baseURL = "https://br676689.xyz"
    //static let baseURL = "http://10.0.0.82:8000"
    //static let baseURL = "http://10.36.13.151:8000"
    //static let baseURL = "http://10.0.0.82:8000"
    
    static let timeout: TimeInterval = 30
}

// MARK: - API Models
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let access_token: String
    let token_type: String
}

struct UserResponse: Codable {
    let id: Int
    let username: String
    let email: String
    let full_name: String?
    let age: Int?
    let height: Double?
    let weight: Double?
    let gender: String?
    let activity_level: String?
    let goal: String?
    let created_at: String
}

struct MealRecordRequest: Codable {
    let meal_type: String
    let food_name: String
    let calories: Double
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let portion_size: String?
    let notes: String?
}

struct MealRecordResponse: Codable {
    let id: Int
    let meal_type: String
    let food_name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let portion_size: String?
    let image_path: String?
    let notes: String?
    let recorded_at: String
}

// MARK: - Weight Record Models
struct WeightRecordRequest: Codable {
    let weight: Double
    let height: Double?
    let notes: String?
}

struct WeightRecordResponse: Codable {
    let id: Int
    let user_id: Int
    let weight: Double
    let height: Double?
    let bmi: Double?
    let notes: String?
    let image_path: String?
    let recorded_at: String
    let created_at: String
    let updated_at: String
}

struct WeightHistoryResponse: Codable {
    let records: [WeightRecordResponse]
    let total_count: Int
    let page: Int
    let page_size: Int
    let has_next: Bool
    let has_prev: Bool
}

struct WeightStatsResponse: Codable {
    let current_weight: Double
    let previous_weight: Double?
    let weight_change: Double
    let weight_change_percentage: Double
    let average_weight: Double
    let min_weight: Double
    let max_weight: Double
    let record_count: Int
    let bmi: Double
    let bmi_category: String
    let period_days: Int
}

struct WeightTrendResponse: Codable {
    let start_date: String
    let end_date: String
    let daily_data: [DailyWeightData]
    let weekly_averages: [WeeklyAverageData]
    let monthly_averages: [MonthlyAverageData]
}

struct DailyWeightData: Codable {
    let date: String
    let weight: Double
    let bmi: Double?
    let notes: String?
}

struct WeeklyAverageData: Codable {
    let week_start: String
    let average_weight: Double
}

struct MonthlyAverageData: Codable {
    let month: String
    let average_weight: Double
}

struct BMICalculationRequest: Codable {
    let weight: Double
    let height: Double
}

struct BMICalculationResponse: Codable {
    let bmi: Double
    let category: String
    let description: String
    let color: String
}

// MARK: - Food Analysis Models
struct FoodAnalysisRequest: Codable {
    let use_ai_portions: Bool
    let manual_override: String
    let portion_slider: Double
}

struct FoodAnalysisItem: Codable {
    let food_detected: String
    let portion_g: Double
    let confidence: Double
    let calories_kcal: Double
    let protein_g: Double
    let carbs_g: Double
    let fat_g: Double
    let source: String
    
    enum CodingKeys: String, CodingKey {
        case food_detected = "Food (detected)"
        case portion_g = "Portion (g)"
        case confidence = "Confidence"
        case calories_kcal = "Calories (kcal)"
        case protein_g = "Protein (g)"
        case carbs_g = "Carbs (g)"
        case fat_g = "Fat (g)"
        case source = "Source"
    }
}

struct FoodAnalysisTotals: Codable {
    let portion_g: Double
    let calories_kcal: Double
    let protein_g: Double
    let carbs_g: Double
    let fat_g: Double
    
    enum CodingKeys: String, CodingKey {
        case portion_g = "Portion (g)"
        case calories_kcal = "Calories (kcal)"
        case protein_g = "Protein (g)"
        case carbs_g = "Carbs (g)"
        case fat_g = "Fat (g)"
    }
}

struct FoodAnalysisResponse: Codable {
    let timestamp: String
    let mode: String
    let per_item: [FoodAnalysisItem]
    let totals: FoodAnalysisTotals
    let notes: String?
    let debug: String?
    let error: String?
}

struct FoodAnalysisConfigResponse: Codable {
    let openai_enabled: Bool
    let model_name: String?
    let fallback_classifier: String
    let openai_error: String?
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(String)
    case unauthorized
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserResponse?
    @Published var authToken: String?
    
    private init() {
        loadAuthToken()
    }
    
    // MARK: - Authentication
    func login(username: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(username: username, password: password)
        let response: LoginResponse = try await performRequest(
            endpoint: "/auth/login",
            method: "POST",
            body: request
        )
        
        authToken = response.access_token
        isAuthenticated = true
        saveAuthToken()
        
        // Fetch user details
        try await fetchCurrentUser()
        
        return response
    }
    
    struct HealthResponse: Codable {
        let status: String
    }
    
    func getHealth() async throws  -> HealthResponse {
        let response: HealthResponse  = try await performRequest(
            endpoint: "/health",
            method: "GET"
        )
        
        return response
    }
    
    func register(username: String, email: String, password: String) async throws -> UserResponse {
        let request = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        let response: UserResponse = try await performRequest(
            endpoint: "/auth/register",
            method: "POST",
            body: request
        )
        
        return response
    }
    
    func fetchCurrentUser() async throws {
        let user: UserResponse = try await performRequest(
            endpoint: "/auth/me",
            method: "GET"
        )
        
        currentUser = user
    }
    
    func logout() {
        authToken = nil
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - Meal Records
    func createMealRecord(
        mealType: String,
        foodName: String,
        calories: Double,
        protein: Double? = nil,
        carbs: Double? = nil,
        fat: Double? = nil,
        portionSize: String? = nil,
        notes: String? = nil,
        image: UIImage? = nil
    ) async throws -> MealRecordResponse {
        
        // Always use multipart form data since backend expects Form parameters
        return try await createMealRecordWithMultipart(
            mealType: mealType,
            foodName: foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            portionSize: portionSize,
            notes: notes,
            image: image
        )
    }
    
    private func createMealRecordWithMultipart(
        mealType: String,
        foodName: String,
        calories: Double,
        protein: Double?,
        carbs: Double?,
        fat: Double?,
        portionSize: String?,
        notes: String?,
        image: UIImage?
    ) async throws -> MealRecordResponse {
        
        guard let url = URL(string: "\(APIConfig.baseURL)/meals/") else {
            throw APIError.invalidURL
        }
        
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add form fields
        let fields: [(String, String)] = [
            ("meal_type", mealType),
            ("food_name", foodName),
            ("calories", String(calories)),
            ("protein", String(protein ?? 0.0)),
            ("carbs", String(carbs ?? 0.0)),
            ("fat", String(fat ?? 0.0)),
            ("portion_size", portionSize ?? ""),
            ("notes", notes ?? "")
        ]
        
        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add image if provided
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"food_image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.unauthorized
        case 422:
            // Validation error - print response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Validation error response: \(responseString)")
            }
            throw APIError.networkError("Validation error - please check your input data")
        default:
            if let responseString = String(data: data, encoding: .utf8) {
                print("Server error response: \(responseString)")
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let mealRecord = try JSONDecoder().decode(MealRecordResponse.self, from: data)
            return mealRecord
        } catch {
            print("Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            throw APIError.decodingError
        }
    }
    
    func getMealRecords() async throws -> [MealRecordResponse] {
        let records: [MealRecordResponse] = try await performRequest(
            endpoint: "/meals/",
            method: "GET"
        )
        return records
    }
    
    func getTodayMealRecords() async throws -> [MealRecordResponse] {
        let records: [MealRecordResponse] = try await performRequest(
            endpoint: "/meals/today",
            method: "GET"
        )
        return records
    }
    
    // MARK: - Weight Records
    func createWeightRecord(weight: Double, height: Double?, notes: String?) async throws -> WeightRecordResponse {
        let request = WeightRecordRequest(weight: weight, height: height, notes: notes)
        let response: WeightRecordResponse = try await performRequest(
            endpoint: "/weight/",
            method: "POST",
            body: request
        )
        return response
    }
    
    func getWeightHistory(page: Int = 1, pageSize: Int = 20) async throws -> WeightHistoryResponse {
        let response: WeightHistoryResponse = try await performRequest(
            endpoint: "/weight/?page=\(page)&page_size=\(pageSize)",
            method: "GET"
        )
        return response
    }
    
    func getWeightStats(days: Int = 30) async throws -> WeightStatsResponse {
        let response: WeightStatsResponse = try await performRequest(
            endpoint: "/weight/stats?days=\(days)",
            method: "GET"
        )
        return response
    }
    
    func getWeightTrend(days: Int = 30) async throws -> WeightTrendResponse {
        let response: WeightTrendResponse = try await performRequest(
            endpoint: "/weight/trend?days=\(days)",
            method: "GET"
        )
        return response
    }
    
    func calculateBMI(weight: Double, height: Double) async throws -> BMICalculationResponse {
        let request = BMICalculationRequest(weight: weight, height: height)
        let response: BMICalculationResponse = try await performRequest(
            endpoint: "/weight/bmi",
            method: "POST",
            body: request
        )
        return response
    }
    
    // MARK: - Generic Request Method
    public func performRequest<T: Codable>(
        endpoint: String,
        method: String,
        body: Codable? = nil
    ) async throws -> T {
        
        guard let url = URL(string: "\(APIConfig.baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = APIConfig.timeout
        
        // Add authentication header if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body for POST/PUT requests
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.networkError("Failed to encode request body")
            }
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse
            } catch {
                print("Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
                throw APIError.decodingError
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Food Analysis
    func analyzeFood(
        image: UIImage,
        useAIPortions: Bool = true,
        manualOverride: String = "",
        portionSlider: Double = 250.0
    ) async throws -> FoodAnalysisResponse {
        
        guard let url = URL(string: "\(APIConfig.baseURL)/api/food/analyze") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = APIConfig.timeout
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"food.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add other parameters
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"use_ai_portions\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(useAIPortions)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"manual_override\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(manualOverride)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"portion_slider\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(portionSlider)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 400:
            throw APIError.networkError("Bad request - please check your image and parameters")
        case 500:
            throw APIError.networkError("Server error - food analysis failed")
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let analysisResult = try JSONDecoder().decode(FoodAnalysisResponse.self, from: data)
            return analysisResult
        } catch {
            print("Food analysis decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
            throw APIError.decodingError
        }
    }
    
    func getFoodAnalysisConfig() async throws -> FoodAnalysisConfigResponse {
        let config: FoodAnalysisConfigResponse = try await performRequest(
            endpoint: "/api/food/config",
            method: "GET"
        )
        return config
    }
    
    func getFoodAnalysisHealth() async throws -> HealthResponse {
        let health: HealthResponse = try await performRequest(
            endpoint: "/api/food/health",
            method: "GET"
        )
        return health
    }
    
    // MARK: - Token Management
    private func saveAuthToken() {
        if let token = authToken {
            UserDefaults.standard.set(token, forKey: "auth_token")
        }
    }
    
    private func loadAuthToken() {
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            authToken = token
            isAuthenticated = true
        }
    }
}

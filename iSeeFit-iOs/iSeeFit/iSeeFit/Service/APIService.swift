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
        
        var request = MealRecordRequest(
            meal_type: mealType,
            food_name: foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            portion_size: portionSize,
            notes: notes
        )
        
        // If we have an image, we need to use multipart form data
        if let image = image {
            return try await createMealRecordWithImage(
                request: request,
                image: image
            )
        } else {
            // Regular JSON request
            let response: MealRecordResponse = try await performRequest(
                endpoint: "/meals/",
                method: "POST",
                body: request
            )
            return response
        }
    }
    
    private func createMealRecordWithImage(
        request: MealRecordRequest,
        image: UIImage
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
            ("meal_type", request.meal_type),
            ("food_name", request.food_name),
            ("calories", String(request.calories)),
            ("protein", request.protein.map(String.init(_:)) ?? "0"),
            ("carbs", request.carbs.map(String.init(_:)) ?? "0"),
            ("fat", request.fat.map(String.init(_:)) ?? "0"),
            ("portion_size", request.portion_size ?? ""),
            ("notes", request.notes ?? "")
        ]
        
        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add image
        if let imageData = image.jpegData(compressionQuality: 0.8) {
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
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let mealRecord = try JSONDecoder().decode(MealRecordResponse.self, from: data)
            return mealRecord
        } catch {
            print("Decoding error: \(error)")
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
    
    // MARK: - Generic Request Method
    private func performRequest<T: Codable>(
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

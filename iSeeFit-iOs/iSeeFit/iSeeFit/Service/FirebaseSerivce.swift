//
//  FirebaseManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-25.
//
//import SwiftUI
import CoreLocation

class IncidentReportService: ObservableObject {
    static let shared = IncidentReportService()
    
    private let baseURL = "http://your-api-domain.com/api"
       
       func reportIncident(
           type: String,
           description: String,
           location: CLLocation
       ) async throws {
           // 构建请求URL
           guard let url = URL(string: "\(baseURL)/incidents") else {
               throw URLError(.badURL)
           }
           
           // 准备请求数据
           let incident = [
               "location": [
                   "_lat": location.coordinate.latitude,
                   "_long": location.coordinate.longitude
               ],
               "type": type,
               "description": description,
               "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
           ] as [String : Any]
           
           // 创建请求
           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           request.httpBody = try JSONSerialization.data(withJSONObject: incident)
           
           // 发送请求
           let (data, response) = try await URLSession.shared.data(for: request)
           
           // 检查响应状态
           guard let httpResponse = response as? HTTPURLResponse,
                 (200...299).contains(httpResponse.statusCode) else {
               throw URLError(.badServerResponse)
           }
       }
   }

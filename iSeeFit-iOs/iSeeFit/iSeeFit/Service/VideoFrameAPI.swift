//
//  VideoFrameAPI.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-27.
//

import Foundation
import UIKit

class VideoFrameAPI: ObservableObject {
        private let baseURL = "\(APIConfig.baseURL)/recommendations"
    //private let baseURL = "http://10.10.10.61:8000/recommendations"
    
    func processVideoToFrames(_ videoURL: URL, userId: String = "default") async throws -> VideoFramesResponse {
        let url = URL(string: "\(baseURL)/process-video-frames/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60.0
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加视频文件
        let videoData = try Data(contentsOf: videoURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video_file\"; filename=\"video.mp4\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(videoData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 添加用户ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(userId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // 添加最大时长
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"max_duration\"\r\n\r\n".data(using: .utf8)!)
        body.append("10".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError1.serverError
        }
        
        let responseData = try JSONDecoder().decode(VideoFramesResponse.self, from: data)
        
        if !responseData.success {
            throw APIError1.processingFailed(responseData.message ?? "Unknown error")
        }
        
        return responseData
    }
}

// 数据模型
struct VideoFramesResponse: Codable {
    let success: Bool
    let frames: [String]?
    let totalFrames: Int?
    let fps: Int?
    let duration: Int?
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success, frames, message, error
        case totalFrames = "total_frames"
        case fps, duration
    }
}

enum APIError1: LocalizedError {
    case serverError
    case processingFailed(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Server Error"
        case .processingFailed(let message):
            return "Processing Failed: \(message)"
        case .invalidResponse:
            return "Invalid Response"
        }
    }
}

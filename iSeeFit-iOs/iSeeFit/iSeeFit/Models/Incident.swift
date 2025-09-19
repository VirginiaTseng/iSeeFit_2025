//
//  Incident.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-26.
//

struct Incident: Codable {
    let latitude: Double
    let longitude: Double
    let type: String
    let description: String
    let timestamp: Int64  // 修改为 Int64 类型
    
    enum IncidentType: String, CaseIterable, Identifiable {
        case hazard = "HAZARD"
        case emergency = "EMERGENCY"
        case suspicious = "SUSPICIOUS"
        case other = "OTHER"
        
        var id: String { self.rawValue }
    }
    
}

//
//  WeatherAlertService.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-21.
//

import Foundation
import CoreLocation
import WeatherKit

// 天气和灾害数据模型
struct WeatherAlertData: Codable {
    let temperature: Double
    let condition: String
    let uvIndex: Int
    let visibility: Double
    let airQuality: Int
    let alerts: [AlertInfo]
    let precipitation: Double
    let windSpeed: Double
    let humidity: Double
    
    // 灾害预警信息
    struct AlertInfo: Codable, Identifiable {
        let id = UUID()
        let type: AlertType
        let severity: AlertSeverity
        let description: String
        let startTime: Date
        let endTime: Date
    }
    
    enum AlertType: String, Codable {
        case storm = "STORM"
        case flood = "FLOOD"
        case earthquake = "EARTHQUAKE"
        case extremeTemperature = "EXTREME_TEMPERATURE"
        case airQuality = "AIR_QUALITY"
        case other = "OTHER"
    }
    
    enum AlertSeverity: String, Codable {
        case low
        case medium
        case high
        case extreme
    }
}

@MainActor
class WeatherAlertService: ObservableObject {
    @Published var weatherData: WeatherAlertData?
    private let locationManager: LocationManager
    private let notificationManager: NotificationManager
    
    // API Keys
    private let openWeatherKey = "YOUR_OPENWEATHER_KEY"
    private let weatherAPIKey = "YOUR_WEATHERAPI_KEY"
    private let aQIAPIKey = "YOUR_AQI_API_KEY"
    
    init(locationManager: LocationManager, notificationManager: NotificationManager) {
        self.locationManager = locationManager
        self.notificationManager = notificationManager
        
        // 开始监听位置变化
        setupLocationMonitoring()
    }
    
    private func setupLocationMonitoring() {
        // 监听位置更新
        Task {
            for await location in locationManager.locationUpdates {
                await fetchWeatherData(for: location)
            }
        }
    }
    
    func fetchWeatherData(for location: CLLocation) async {
        async let weatherData = fetchOpenWeatherData(location)
        async let alertData = fetchWeatherAlerts(location)
       // async let aqiData = fetchAirQualityData(location)
        
        do {
            let (weather, alerts) = await (try weatherData, try alertData)//, try aqiData)
            
            // 整合数据
            let combinedData = WeatherAlertData(    temperature: weather.main.temp,
                                                    condition: weather.weather.first?.description ?? "Unknown",
                                                    uvIndex: weather.main.temp > 25 ? 8 : 4, // 简单UV指数估算
                                                    visibility: Double(weather.visibility) / 1000.0, // 转换为公里
                                                    airQuality: 8,//aqi.data.aqi,
                                                    alerts: [],//processAlerts(weather, aqi), // 处理所有预警信息
                                                    precipitation: 0.0,//weather.rain?.oneHour ?? 0.0,
                                                    windSpeed: 10,//weather.wind.speed,
                                                    humidity:20// weather.main.humidity
            )
            
            // 更新UI
            self.weatherData = combinedData
            
            // 检查是否需要发送预警通知
            checkAndSendAlerts(combinedData.alerts)
        } catch {
            print("Error fetching weather data: \(error)")
        }
    }
    
    // OpenWeather API
    private func fetchOpenWeatherData(_ location: CLLocation) async throws -> OpenWeatherResponse {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=\(openWeatherKey)&units=metric"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
    }
    
    // WeatherAPI.com for detailed forecasts
    private func fetchWeatherAlerts(_ location: CLLocation) async throws -> [WeatherAlertData.AlertInfo] {
        let urlString = "http://api.weatherapi.com/v1/forecast.json?key=\(weatherAPIKey)&q=\(location.coordinate.latitude),\(location.coordinate.longitude)&alerts=yes"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        // Parse response and convert to AlertInfo array
        return []
    }
    
    // Air Quality API
//    private func fetchAirQualityData(_ location: CLLocation) async throws -> AQIData {
//        let urlString = "https://api.waqi.info/feed/geo:\(location.coordinate.latitude);\(location.coordinate.longitude)/?token=\(aQIAPIKey)"
//        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
//        
//        let (data, _) = try await URLSession.shared.data(from: url)
//        return try JSONDecoder().decode(AQIData.self, from: data)
//    }
    
    // 检查并发送预警通知
    private func checkAndSendAlerts(_ alerts: [WeatherAlertData.AlertInfo]) {
        for alert in alerts {
            // 根据严重程度决定通知类型
            switch alert.severity {
            case .extreme:
                notificationManager.sendSafetyAlert(
                    level: "Extreme",
                    message: "⚠️ \(alert.type.rawValue): \(alert.description)"
                )
            case .high:
                notificationManager.sendSafetyAlert(
                    level: "High",
                    message: "⚠️ \(alert.description)"
                )
            case .medium:
                notificationManager.sendNotificationWithImage(
                    title: "Weather Alert",
                    body: alert.description,
                    imageName: getAlertIcon(for: alert.type)
                )
            case .low:
                // 可能只在 App 内显示，不发送通知
                break
            }
        }
    }
    
    // 获取警报图标
    private func getAlertIcon(for alertType: WeatherAlertData.AlertType) -> String {
        switch alertType {
        case .storm: return "cloud.bolt.fill"
        case .flood: return "water.waves"
        case .earthquake: return "waveform.path.ecg"
        case .extremeTemperature: return "thermometer.sun.fill"
        case .airQuality: return "aqi.high"
        case .other: return "exclamationmark.triangle.fill"
        }
    }
}

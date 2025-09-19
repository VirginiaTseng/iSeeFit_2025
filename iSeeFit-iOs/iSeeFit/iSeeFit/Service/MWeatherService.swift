//
//  WeatherService.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-19.
//
import Foundation
import WeatherKit
import CoreLocation

//struct WeatherData: Codable {
//    let temperature: Double
//    let condition: String
//    let uvIndex: Int
//    let visibility: Double
//    let airQuality: Int
//}

@MainActor
class MWeatherService: ObservableObject {
    @Published var weatherData: WeatherData?
//    private let weatherService = WeatherService.shared
    
    func fetchWeather(latitude: Double, longitude: Double) async {
//        Task {
//            
//            do {
//                let location = CLLocation(latitude: latitude, longitude: longitude)
//                let weather = try await weatherService.weather(for: location)
//                
//                // Get current weather conditions
//                let current = weather.currentWeather
//                
//                // Get air quality data
//                let airQualityData=20//try await weatherService.weather(for: location, including: .airQuality)
//                let airQualityIndex = 20//airQualityData.airQuality?.condition.index ?? 0
//                
//                weatherData = WeatherData(
//                    temperature: current.temperature.value,
//                    condition: current.condition.description,
//                    uvIndex: current.uvIndex.value,
//                    visibility: current.visibility.value,
//                    airQuality: airQualityIndex
//                )
//            } catch {
//                print("Error fetching weather: \(error)")
//            }
//            
//        }
    }
}

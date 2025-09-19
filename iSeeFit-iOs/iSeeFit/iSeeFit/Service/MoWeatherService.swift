//
//  MoWeatherService.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-19.
//

import Foundation
import CoreLocation

struct WeatherData: Codable {
    let temperature: Double
    let condition: String
    let uvIndex: Int
    let visibility: Double
    let airQuality: Int
}

// OpenWeatherMap API Response structures
struct OpenWeatherResponse: Codable {
    let main: MainWeather
    let weather: [Weather]
    let visibility: Int
    
    struct MainWeather: Codable {
        let temp: Double
    }
    
    struct Weather: Codable {
        let description: String
    }
}

@MainActor
class MoWeatherService: ObservableObject {
    @Published var weatherData: WeatherData?
    private let apiKey = "YOUR_API_KEY" // 需要在 OpenWeatherMap 注册获取
    
    func fetchWeather(latitude: Double, longitude: Double) async {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let weatherResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
            
            // Convert the response to our WeatherData model
            weatherData = WeatherData(
                temperature: weatherResponse.main.temp,
                condition: weatherResponse.weather.first?.description ?? "Unknown",
                uvIndex: 0, // OpenWeatherMap free API doesn't include UV index
                visibility: Double(weatherResponse.visibility) / 1000.0, // Convert to kilometers
                airQuality: 0 // Would need separate API call for air quality
            )
        } catch {
            print("Error fetching weather: \(error)")
        }
    }
    
    // For testing/development
    func fetchMockWeather() {
        weatherData = WeatherData(
            temperature: 22.5,
            condition: "Partly cloudy",
            uvIndex: 3,
            visibility: 10.0,
            airQuality: 50
        )
    }
}

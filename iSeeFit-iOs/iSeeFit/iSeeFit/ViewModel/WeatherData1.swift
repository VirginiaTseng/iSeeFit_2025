//
//  WeatherData.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-19.
//

import Foundation
import CoreLocation

struct WeatherData1: Codable {
    let condition : String
    let temperature:Double
    let locationName: String
}

struct WeatherResponse: Codable {
    let name: String
    let main: MainWeather
    let weather: [Weather]
}

struct MainWeather: Codable {
    let temp: Double
}

struct Weather: Codable {
    let main: String
}


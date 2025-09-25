//
//  FoodLocalStore.swift
//  iSeeFit
//
//  Provides lightweight local persistence for food records using UserDefaults.
//

import Foundation
import SwiftUI

final class FoodLocalStore: ObservableObject {
    static let shared = FoodLocalStore()
    private init() {
        // Load existing records from UserDefaults
        _ = loadRecords()
    }
    
    // Published property for SwiftUI updates
    @Published private(set) var records: [FoodRecord] = []
    
    private let recordsKey = "local_food_records"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Date formatter for consistent date handling
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func loadRecords() -> [FoodRecord] {
        guard let data = UserDefaults.standard.data(forKey: recordsKey) else {
            print("DEBUG: FoodLocalStore - no local records found")
            records = []
            return []
        }
        do {
            let loadedRecords = try decoder.decode([FoodRecord].self, from: data)
            print("DEBUG: FoodLocalStore - loaded \(loadedRecords.count) local records")
            records = loadedRecords
            return loadedRecords
        } catch {
            print("ERROR: FoodLocalStore - decode failed: \(error)")
            records = []
            return []
        }
    }
    
    func saveRecords(_ recordsToSave: [FoodRecord]) {
        do {
            let data = try encoder.encode(recordsToSave)
            UserDefaults.standard.set(data, forKey: recordsKey)
            records = recordsToSave
            print("DEBUG: FoodLocalStore - saved \(recordsToSave.count) records locally")
        } catch {
            print("ERROR: FoodLocalStore - encode failed: \(error)")
        }
    }
    
    func addRecord(_ record: FoodRecord) {
        // Add new record
        records.append(record)
        
        // Keep sorted by date descending for quick display
        records.sort { $0.date > $1.date }
        saveRecords(records)
        
        print("DEBUG: FoodLocalStore - added new record: \(record.foodName) (\(record.calories)kcal) @ \(record.date)")
    }
    
    func updateRecord(_ record: FoodRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveRecords(records)
            print("DEBUG: FoodLocalStore - updated record: \(record.foodName) (\(record.calories)kcal)")
        } else {
            print("WARNING: FoodLocalStore - record not found for update: \(record.id)")
        }
    }
    
    func deleteRecord(_ record: FoodRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords(records)
        print("DEBUG: FoodLocalStore - deleted record: \(record.foodName)")
    }
    
    func getRecordsForDate(_ date: Date) -> [FoodRecord] {
        return records.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func getRecordsForDateRange(_ startDate: Date, _ endDate: Date) -> [FoodRecord] {
        return records.filter { record in
            record.date >= startDate && record.date <= endDate
        }
    }
    
    func getTodayRecords() -> [FoodRecord] {
        return getRecordsForDate(Date())
    }
    
    func getWeekRecords() -> [FoodRecord] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        return getRecordsForDateRange(weekAgo, today)
    }
    
    func getMonthRecords() -> [FoodRecord] {
        let calendar = Calendar.current
        let today = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        return getRecordsForDateRange(monthAgo, today)
    }
    
    func getStatistics() -> FoodStatistics {
        return FoodStatistics(records: records)
    }
    
    func getTodayStatistics() -> FoodStatistics {
        let records = getTodayRecords()
        return FoodStatistics(records: records)
    }
    
    func getWeekStatistics() -> FoodStatistics {
        let records = getWeekRecords()
        return FoodStatistics(records: records)
    }
    
    func getMonthStatistics() -> FoodStatistics {
        let records = getMonthRecords()
        return FoodStatistics(records: records)
    }
    
    func clearAllRecords() {
        UserDefaults.standard.removeObject(forKey: recordsKey)
        records = []
        print("DEBUG: FoodLocalStore - cleared all records")
    }
    
    func exportRecords() -> Data? {
        do {
            return try encoder.encode(records)
        } catch {
            print("ERROR: FoodLocalStore - export failed: \(error)")
            return nil
        }
    }
    
    func importRecords(from data: Data) -> Bool {
        do {
            let records = try decoder.decode([FoodRecord].self, from: data)
            saveRecords(records)
            print("DEBUG: FoodLocalStore - imported \(records.count) records")
            return true
        } catch {
            print("ERROR: FoodLocalStore - import failed: \(error)")
            return false
        }
    }
}

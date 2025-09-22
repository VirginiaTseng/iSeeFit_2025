//
//  WeightLocalStore.swift
//  iSeeFit
//
//  Provides lightweight local persistence for weight records using UserDefaults.
//

import Foundation

final class WeightLocalStore {
    static let shared = WeightLocalStore()
    private init() {}
    
    private let recordsKey = "local_weight_records"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func loadRecords() -> [WeightRecord] {
        guard let data = UserDefaults.standard.data(forKey: recordsKey) else {
            print("DEBUG: WeightLocalStore - no local records found")
            return []
        }
        do {
            let records = try decoder.decode([WeightRecord].self, from: data)
            print("DEBUG: WeightLocalStore - loaded \(records.count) local records")
            return records
        } catch {
            print("ERROR: WeightLocalStore - decode failed: \(error)")
            return []
        }
    }
    
    func saveRecords(_ records: [WeightRecord]) {
        do {
            let data = try encoder.encode(records)
            UserDefaults.standard.set(data, forKey: recordsKey)
            print("DEBUG: WeightLocalStore - saved \(records.count) records locally")
        } catch {
            print("ERROR: WeightLocalStore - encode failed: \(error)")
        }
    }
    
    func addRecord(_ record: WeightRecord) {
        var current = loadRecords()
        current.append(record)
        // Keep sorted by date descending for quick display
        current.sort { $0.date > $1.date }
        saveRecords(current)
    }
}



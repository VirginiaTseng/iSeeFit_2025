import Foundation
import SwiftUI

// MARK: - Record Manager
class RecordManager: ObservableObject {
    static let shared = RecordManager()
    
    @Published var dailyRecords: [DailyRecord] = [] // Array of all daily records
    @Published var currentRecord: DailyRecord // Current day's record
    
    private let userDefaults = UserDefaults.standard // UserDefaults for data persistence
    private let recordsKey = "DailyRecords" // Key for storing records in UserDefaults
    
    // Private initializer for singleton pattern
    private init() {
        print("DEBUG: Initializing RecordManager singleton")
        self.currentRecord = DailyRecord()
        loadRecords()
        updateCurrentRecord()
        print("DEBUG: RecordManager initialization completed")
    }
    
    // MARK: - Data Persistence
    private func saveRecords() {
        print("DEBUG: Attempting to save \(dailyRecords.count) daily records")
        do {
            let data = try JSONEncoder().encode(dailyRecords)
            userDefaults.set(data, forKey: recordsKey)
            print("DEBUG: Successfully saved records to UserDefaults")
        } catch {
            print("ERROR: Failed to save records: \(error)")
        }
    }
    
    private func loadRecords() {
        print("DEBUG: Attempting to load records from UserDefaults")
        guard let data = userDefaults.data(forKey: recordsKey) else { 
            print("DEBUG: No existing records found in UserDefaults")
            return 
        }
        
        do {
            dailyRecords = try JSONDecoder().decode([DailyRecord].self, from: data)
            print("DEBUG: Successfully loaded \(dailyRecords.count) records from UserDefaults")
        } catch {
            print("ERROR: Failed to load records: \(error)")
        }
    }
    
    // MARK: - Current Record Management
    private func updateCurrentRecord() {
        let today = Calendar.current.startOfDay(for: Date())
        print("DEBUG: Updating current record for date: \(today)")
        
        if let existingRecord = dailyRecords.first(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: today) 
        }) {
            currentRecord = existingRecord
            print("DEBUG: Found existing record for today")
        } else {
            currentRecord = DailyRecord(date: today)
            dailyRecords.append(currentRecord)
            print("DEBUG: Created new record for today")
            saveRecords()
        }
    }
    
    // MARK: - Meal Record Operations
    func addMealRecord(_ meal: MealRecord) {
        print("DEBUG: Adding meal record: \(meal.mealType.rawValue) with \(meal.totalCalories) calories")
        currentRecord.meals.append(meal)
        currentRecord.totalCaloriesIntake += meal.totalCalories
        print("DEBUG: Updated total calories intake to: \(currentRecord.totalCaloriesIntake)")
        updateRecord()
    }
    
    func addFoodToMeal(_ food: FoodItem, mealType: MealRecord.MealType) {
        let timestamp = Date()
        print("DEBUG: Adding food \(food.name) to \(mealType.rawValue) meal")
        
        // Find existing meal record or create new one
        if let index = currentRecord.meals.firstIndex(where: { $0.mealType == mealType }) {
            currentRecord.meals[index].foodItems.append(food)
            currentRecord.meals[index].totalCalories += food.calories
            print("DEBUG: Added food to existing \(mealType.rawValue) meal")
        } else {
            let newMeal = MealRecord(
                timestamp: timestamp,
                mealType: mealType,
                foodItems: [food],
                totalCalories: food.calories,
                imagePath: nil
            )
            currentRecord.meals.append(newMeal)
            print("DEBUG: Created new \(mealType.rawValue) meal record")
        }
        
        currentRecord.totalCaloriesIntake += food.calories
        print("DEBUG: Updated total calories intake to: \(currentRecord.totalCaloriesIntake)")
        updateRecord()
    }
    
    // MARK: - Workout Record Operations
    func addWorkoutRecord(_ workout: WorkoutRecord) {
        print("DEBUG: Adding workout record: \(workout.workoutType) with \(workout.caloriesBurned) calories burned")
        currentRecord.workouts.append(workout)
        currentRecord.totalCaloriesBurned += workout.caloriesBurned
        print("DEBUG: Updated total calories burned to: \(currentRecord.totalCaloriesBurned)")
        updateRecord()
    }
    
    // MARK: - Image Processing
    func saveMealImage(_ image: Image, for meal: MealRecord) -> String? {
        let filename = "meal_\(meal.id.uuidString)"
        print("DEBUG: Saving meal image with filename: \(filename)")
        return ImageCompressor.compressAndSave(image, filename: filename)
    }
    
    func saveWorkoutImage(_ image: Image, for workout: WorkoutRecord) -> String? {
        let filename = "workout_\(workout.id.uuidString)"
        print("DEBUG: Saving workout image with filename: \(filename)")
        return ImageCompressor.compressAndSave(image, filename: filename)
    }
    
    // MARK: - Historical Record Queries
    func getRecordsForDateRange(_ startDate: Date, _ endDate: Date) -> [DailyRecord] {
        print("DEBUG: Querying records from \(startDate) to \(endDate)")
        let filteredRecords = dailyRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }.sorted { $0.date > $1.date }
        print("DEBUG: Found \(filteredRecords.count) records in date range")
        return filteredRecords
    }
    
    func getRecordsForLastDays(_ days: Int) -> [DailyRecord] {
        print("DEBUG: Querying records for last \(days) days")
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return getRecordsForDateRange(startDate, endDate)
    }
    
    // MARK: - Statistics Functions
    func getWeeklyStats() -> (totalIntake: Int, totalBurned: Int, averageNet: Int) {
        print("DEBUG: Calculating weekly statistics")
        let weekRecords = getRecordsForLastDays(7)
        let totalIntake = weekRecords.reduce(0) { $0 + $1.totalCaloriesIntake }
        let totalBurned = weekRecords.reduce(0) { $0 + $1.totalCaloriesBurned }
        let averageNet = weekRecords.isEmpty ? 0 : (totalIntake - totalBurned) / weekRecords.count
        
        print("DEBUG: Weekly stats - Intake: \(totalIntake), Burned: \(totalBurned), Average Net: \(averageNet)")
        return (totalIntake, totalBurned, averageNet)
    }
    
    // MARK: - Private Methods
    private func updateRecord() {
        print("DEBUG: Updating record for date: \(currentRecord.date)")
        if let index = dailyRecords.firstIndex(where: { 
            Calendar.current.isDate($0.date, inSameDayAs: currentRecord.date) 
        }) {
            dailyRecords[index] = currentRecord
            print("DEBUG: Updated existing record at index \(index)")
        } else {
            dailyRecords.append(currentRecord)
            print("DEBUG: Added new record to dailyRecords array")
        }
        saveRecords()
    }
}

// MARK: - Extension: Date Formatting
extension Date {
    func formattedForDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd" // Format: Jan 15
        return formatter.string(from: self)
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isYesterday() -> Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

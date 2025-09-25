//
//  FoodStorageTest.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-25.
//  Test utility for food local storage functionality
//

import Foundation

class FoodStorageTest {
    static let shared = FoodStorageTest()
    private init() {}
    
    func runTests() {
        print("🧪 Starting Food Storage Tests...")
        
        // Test 1: Create sample food records
        testCreateSampleRecords()
        
        // Test 2: Test local storage operations
        testLocalStorageOperations()
        
        // Test 3: Test statistics calculation
        testStatisticsCalculation()
        
        // Test 4: Test date filtering
        testDateFiltering()
        
        print("✅ Food Storage Tests Completed!")
    }
    
    private func testCreateSampleRecords() {
        print("📝 Test 1: Creating sample food records...")
        
        let sampleFoods = [
            ("Apple", 52.0, 0.3, 14.0, 0.2),
            ("Banana", 89.0, 1.1, 23.0, 0.3),
            ("Chicken Breast", 165.0, 31.0, 0.0, 3.6),
            ("Rice", 130.0, 2.7, 28.0, 0.3),
            ("Salad", 20.0, 1.0, 4.0, 0.2)
        ]
        
        let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
        
        for (index, food) in sampleFoods.enumerated() {
            let detectedFoods = [
                DetectedFoodItem(
                    foodName: food.0,
                    portionGrams: Double.random(in: 100...300),
                    confidence: Double.random(in: 0.7...0.95),
                    calories: food.1,
                    protein: food.2,
                    carbs: food.3,
                    fat: food.4,
                    source: "test"
                )
            ]
            
            let record = FoodRecord(
                mealType: mealTypes[index % mealTypes.count],
                foodName: food.0,
                calories: food.1,
                protein: food.2,
                carbs: food.3,
                fat: food.4,
                portionSize: "\(Int.random(in: 100...300))g",
                notes: "Test record \(index + 1)",
                imagePath: nil,
                analysisMode: "test_mode",
                detectedFoods: detectedFoods,
                date: Date().addingTimeInterval(-Double(index * 3600)) // Spread over hours
            )
            
            FoodLocalStore.shared.addRecord(record)
            print("  ✅ Created record: \(food.0) (\(food.1) kcal)")
        }
    }
    
    private func testLocalStorageOperations() {
        print("💾 Test 2: Testing local storage operations...")
        
        // Test loading records
        let allRecords = FoodLocalStore.shared.loadRecords()
        print("  📊 Total records loaded: \(allRecords.count)")
        
        // Test today's records
        let todayRecords = FoodLocalStore.shared.getTodayRecords()
        print("  📅 Today's records: \(todayRecords.count)")
        
        // Test week's records
        let weekRecords = FoodLocalStore.shared.getWeekRecords()
        print("  📆 This week's records: \(weekRecords.count)")
        
        // Test month's records
        let monthRecords = FoodLocalStore.shared.getMonthRecords()
        print("  📅 This month's records: \(monthRecords.count)")
        
        // Test date-specific records
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayRecords = FoodLocalStore.shared.getRecordsForDate(yesterday)
        print("  📅 Yesterday's records: \(yesterdayRecords.count)")
    }
    
    private func testStatisticsCalculation() {
        print("📈 Test 3: Testing statistics calculation...")
        
        let allStats = FoodLocalStore.shared.getStatistics()
        print("  📊 All time stats:")
        print("    - Total calories: \(Int(allStats.totalCalories))")
        print("    - Total protein: \(String(format: "%.1f", allStats.totalProtein))g")
        print("    - Total carbs: \(String(format: "%.1f", allStats.totalCarbs))g")
        print("    - Total fat: \(String(format: "%.1f", allStats.totalFat))g")
        print("    - Meal count: \(allStats.mealCount)")
        print("    - Average calories per meal: \(String(format: "%.1f", allStats.averageCaloriesPerMeal))")
        print("    - Most common meal type: \(allStats.mostCommonMealType)")
        
        let todayStats = FoodLocalStore.shared.getTodayStatistics()
        print("  📅 Today's stats:")
        print("    - Total calories: \(Int(todayStats.totalCalories))")
        print("    - Meal count: \(todayStats.mealCount)")
    }
    
    private func testDateFiltering() {
        print("🗓️ Test 4: Testing date filtering...")
        
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        let dateRangeRecords = FoodLocalStore.shared.getRecordsForDateRange(weekAgo, today)
        print("  📅 Records in last week: \(dateRangeRecords.count)")
        
        // Test meal type filtering
        let allRecords = FoodLocalStore.shared.loadRecords()
        let breakfastRecords = allRecords.filter { $0.mealType == "breakfast" }
        let lunchRecords = allRecords.filter { $0.mealType == "lunch" }
        let dinnerRecords = allRecords.filter { $0.mealType == "dinner" }
        let snackRecords = allRecords.filter { $0.mealType == "snack" }
        
        print("  🍳 Breakfast records: \(breakfastRecords.count)")
        print("  🍽️ Lunch records: \(lunchRecords.count)")
        print("  🍴 Dinner records: \(dinnerRecords.count)")
        print("  🍿 Snack records: \(snackRecords.count)")
    }
    
    func cleanupTestData() {
        print("🧹 Cleaning up test data...")
        FoodLocalStore.shared.clearAllRecords()
        print("  ✅ Test data cleaned up")
    }
    
    func demonstrateUsage() {
        print("📚 Food Storage Usage Demonstration:")
        print("")
        print("1. Create a food record:")
        print("   let record = FoodRecord(mealType: \"breakfast\", foodName: \"Oatmeal\", ...)")
        print("   FoodLocalStore.shared.addRecord(record)")
        print("")
        print("2. Load records:")
        print("   let allRecords = FoodLocalStore.shared.loadRecords()")
        print("   let todayRecords = FoodLocalStore.shared.getTodayRecords()")
        print("")
        print("3. Get statistics:")
        print("   let stats = FoodLocalStore.shared.getStatistics()")
        print("   print(\"Total calories: \\(stats.totalCalories)\")")
        print("")
        print("4. Filter by date:")
        print("   let dateRecords = FoodLocalStore.shared.getRecordsForDate(someDate)")
        print("")
        print("5. Save images:")
        print("   let imagePath = ImageManager.shared.saveFoodImage(image, recordId: record.id)")
        print("")
    }
}

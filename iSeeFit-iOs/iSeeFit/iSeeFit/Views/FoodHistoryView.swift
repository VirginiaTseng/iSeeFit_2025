//
//  FoodHistoryView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-25.
//

import SwiftUI

struct FoodHistoryView: View {
    @StateObject private var foodLocalStore = FoodLocalStore.shared
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var showingStatistics = false
    @State private var selectedRecord: FoodRecord?
    @State private var showingRecordDetail = false
    
    // Filter options
    @State private var selectedMealType: MealType? = nil
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date selector
                dateSelectorView
                
                // Statistics summary
                statisticsView
                
                // Records list
                recordsListView
            }
            .navigationTitle("Food History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filters") {
                        showingFilters = true
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingStatistics) {
                FoodStatisticsView()
            }
            .sheet(isPresented: $showingFilters) {
                FoodFiltersView(selectedMealType: $selectedMealType)
            }
            .sheet(isPresented: $showingRecordDetail) {
                if let record = selectedRecord {
                    FoodRecordDetailView(record: record)
                }
            }
        }
    }
    
    // MARK: - Date Selector
    private var dateSelectorView: some View {
        HStack {
            Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            
            Spacer()
            
            Button(action: { showingDatePicker = true }) {
                VStack {
                    Text(selectedDate, style: .date)
                        .font(.headline)
                    Text("\(recordsForSelectedDate.count) records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Statistics View
    private var statisticsView: some View {
        let stats = FoodStatistics(records: recordsForSelectedDate)
        
        return VStack(spacing: 12) {
            HStack {
                Text("Daily Summary")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    showingStatistics = true
                }
                .font(.caption)
            }
            
            HStack(spacing: 20) {
                StatisticItem(
                    title: "Calories",
                    value: "\(Int(stats.totalCalories))",
                    unit: "kcal",
                    color: .orange
                )
                
                StatisticItem(
                    title: "Protein",
                    value: String(format: "%.1f", stats.totalProtein),
                    unit: "g",
                    color: .blue
                )
                
                StatisticItem(
                    title: "Carbs",
                    value: String(format: "%.1f", stats.totalCarbs),
                    unit: "g",
                    color: .green
                )
                
                StatisticItem(
                    title: "Fat",
                    value: String(format: "%.1f", stats.totalFat),
                    unit: "g",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Records List
    private var recordsListView: some View {
        List {
            ForEach(filteredRecords) { record in
                FoodRecordRow(record: record) {
                    selectedRecord = record
                    showingRecordDetail = true
                }
            }
            .onDelete(perform: deleteRecords)
        }
        .listStyle(.plain)
    }
    
    // MARK: - Computed Properties
    private var recordsForSelectedDate: [FoodRecord] {
        foodLocalStore.getRecordsForDate(selectedDate)
    }
    
    private var filteredRecords: [FoodRecord] {
        var records = recordsForSelectedDate
        
        if let mealType = selectedMealType {
            records = records.filter { $0.mealType == mealType.rawValue }
        }
        
        return records.sorted { $0.date > $1.date }
    }
    
    // MARK: - Actions
    private func deleteRecords(offsets: IndexSet) {
        let records = filteredRecords
        for index in offsets {
            let record = records[index]
            foodLocalStore.deleteRecord(record)
            
            // Also delete associated image if exists
            if let imagePath = record.imagePath {
                ImageManager.shared.deleteImage(at: imagePath)
            }
        }
    }
}

// MARK: - Supporting Views
struct StatisticItem: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct FoodRecordRow: View {
    let record: FoodRecord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Meal type icon
                VStack {
                    Image(systemName: mealTypeIcon)
                        .font(.title2)
                        .foregroundColor(mealTypeColor)
                    Text(mealTypeDisplayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 50)
                
                // Food info
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.foodName)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    if let notes = record.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Text(record.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Nutrition info
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(record.calories))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("kcal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("P: \(String(format: "%.1f", record.protein))g")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        
                        Text("C: \(String(format: "%.1f", record.carbs))g")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Text("F: \(String(format: "%.1f", record.fat))g")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private var mealTypeIcon: String {
        switch record.mealType {
        case "breakfast": return "sunrise"
        case "lunch": return "sun.max"
        case "dinner": return "sunset"
        case "snack": return "leaf"
        default: return "fork.knife"
        }
    }
    
    private var mealTypeColor: Color {
        switch record.mealType {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .blue
        case "snack": return .green
        default: return .gray
        }
    }
    
    private var mealTypeDisplayName: String {
        switch record.mealType {
        case "breakfast": return "Breakfast"
        case "lunch": return "Lunch"
        case "dinner": return "Dinner"
        case "snack": return "Snack"
        default: return "Meal"
        }
    }
}

struct FoodFiltersView: View {
    @Binding var selectedMealType: MealType?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Meal Type") {
                    Button("All Meals") {
                        selectedMealType = nil
                    }
                    .foregroundColor(selectedMealType == nil ? .blue : .primary)
                    
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        Button(mealType.displayName) {
                            selectedMealType = mealType
                        }
                        .foregroundColor(selectedMealType == mealType ? .blue : .primary)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FoodRecordDetailView: View {
    let record: FoodRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showingImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(record.foodName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Label(mealTypeDisplayName, systemImage: mealTypeIcon)
                                .foregroundColor(mealTypeColor)
                            
                            Spacer()
                            
                            Text(record.date, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Image if available
                    if let imagePath = record.imagePath,
                       let image = ImageManager.shared.loadImage(from: imagePath) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                            .onTapGesture {
                                showingImage = image
                            }
                    }
                    
                    // Nutrition summary
                    nutritionSummaryView
                    
                    // Detected foods
                    if !record.detectedFoods.isEmpty {
                        detectedFoodsView
                    }
                    
                    // Notes
                    if let notes = record.notes, !notes.isEmpty {
                        notesView(notes)
                    }
                    
                    // Analysis info
                    analysisInfoView
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: .constant(showingImage != nil)) {
            if let image = showingImage {
                ImageViewerView(image: image) {
                    showingImage = nil
                }
            }
        }
    }
    
    private var nutritionSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Summary")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                NutritionCard(title: "Calories", value: "\(Int(record.calories))", unit: "kcal", color: .orange)
                NutritionCard(title: "Protein", value: String(format: "%.1f", record.protein), unit: "g", color: .blue)
                NutritionCard(title: "Carbs", value: String(format: "%.1f", record.carbs), unit: "g", color: .green)
                NutritionCard(title: "Fat", value: String(format: "%.1f", record.fat), unit: "g", color: .red)
            }
        }
    }
    
    private var detectedFoodsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Foods")
                .font(.headline)
            
            ForEach(record.detectedFoods) { food in
                HStack {
                    VStack(alignment: .leading) {
                        Text(food.foodName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(String(format: "%.1f", food.portionGrams))g • \(String(format: "%.0f%%", food.confidence * 100)) confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(food.calories)) kcal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func notesView(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            
            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    private var analysisInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analysis Info")
                .font(.headline)
            
            HStack {
                Text("Mode:")
                    .foregroundColor(.secondary)
                Text(record.analysisMode)
                    .fontWeight(.medium)
                Spacer()
            }
            
            if let portionSize = record.portionSize, !portionSize.isEmpty {
                HStack {
                    Text("Portion Size:")
                        .foregroundColor(.secondary)
                    Text(portionSize)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
    }
    
    private var mealTypeIcon: String {
        switch record.mealType {
        case "breakfast": return "sunrise"
        case "lunch": return "sun.max"
        case "dinner": return "sunset"
        case "snack": return "leaf"
        default: return "fork.knife"
        }
    }
    
    private var mealTypeColor: Color {
        switch record.mealType {
        case "breakfast": return .orange
        case "lunch": return .yellow
        case "dinner": return .blue
        case "snack": return .green
        default: return .gray
        }
    }
    
    private var mealTypeDisplayName: String {
        switch record.mealType {
        case "breakfast": return "Breakfast"
        case "lunch": return "Lunch"
        case "dinner": return "Dinner"
        case "snack": return "Snack"
        default: return "Meal"
        }
    }
}

struct NutritionCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ImageViewerView: View {
    let image: UIImage
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            onDismiss()
                        }
                    }
                }
        }
    }
}

struct FoodStatisticsView: View {
    @StateObject private var foodLocalStore = FoodLocalStore.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's statistics
                    statisticsSection("Today", stats: foodLocalStore.getTodayStatistics())
                    
                    // This week's statistics
                    statisticsSection("This Week", stats: foodLocalStore.getWeekStatistics())
                    
                    // This month's statistics
                    statisticsSection("This Month", stats: foodLocalStore.getMonthStatistics())
                    
                    // All time statistics
                    statisticsSection("All Time", stats: foodLocalStore.getStatistics())
                }
                .padding()
            }
            .navigationTitle("Food Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func statisticsSection(_ title: String, stats: FoodStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                NutritionCard(title: "Total Calories", value: "\(Int(stats.totalCalories))", unit: "kcal", color: .orange)
                NutritionCard(title: "Total Protein", value: String(format: "%.1f", stats.totalProtein), unit: "g", color: .blue)
                NutritionCard(title: "Total Carbs", value: String(format: "%.1f", stats.totalCarbs), unit: "g", color: .green)
                NutritionCard(title: "Total Fat", value: String(format: "%.1f", stats.totalFat), unit: "g", color: .red)
            }
            
            HStack {
                Text("Meals: \(stats.mealCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Avg: \(String(format: "%.1f", stats.averageCaloriesPerMeal)) kcal/meal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct FoodHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        FoodHistoryView()
    }
}

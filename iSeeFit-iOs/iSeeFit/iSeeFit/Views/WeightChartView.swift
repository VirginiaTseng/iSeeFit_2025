//
//  WeightChartView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-19.
//

import SwiftUI
import Charts

struct WeightChartView: View {
    @State private var weightRecords: [WeightRecord] = []
    @State private var selectedTimeRange: TimeRange = .week
    @State private var isLoading = false
    @State private var showAddWeight = false
    
    // User height for BMI calculation
    private let userHeight: Double = 170.0 // TODO: Get from user profile
    
    // Filtered records based on selected time range
    private var filteredRecords: [WeightRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return weightRecords.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return weightRecords.filter { $0.date >= monthAgo }
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return weightRecords.filter { $0.date >= threeMonthsAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return weightRecords.filter { $0.date >= yearAgo }
        }
    }
    
    // Weight statistics
    private var statistics: WeightStatistics {
        WeightStatistics(records: filteredRecords, height: userHeight)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Statistics Cards
                    statisticsCards
                    
                    // Weight Chart
                    weightChart
                    
                    // BMI Chart
                    bmiChart
                    
                    // Recent Records
                    recentRecords
                }
                .padding()
            }
            .navigationTitle("Weight Tracking")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddWeight = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddWeight) {
                WeightInputView()
            }
            .onAppear {
                loadWeightRecords()
            }
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Time Range")
                    .font(.headline)
                Spacer()
            }
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Statistics Cards
    private var statisticsCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // Current Weight Card
            StatCard(
                title: "Current Weight",
                value: String(format: "%.1f kg", statistics.currentWeight),
                subtitle: statistics.weightChange != 0 ? 
                    String(format: "%+.1f kg", statistics.weightChange) : "No change",
                color: statistics.weightChange > 0 ? .red : 
                       statistics.weightChange < 0 ? .green : .blue,
                icon: "scalemass.fill"
            )
            
            // BMI Card
            StatCard(
                title: "BMI",
                value: String(format: "%.1f", statistics.bmi),
                subtitle: statistics.bmiCategory.description,
                color: statistics.bmiCategory.color,
                icon: "heart.fill"
            )
            
            // Average Weight Card
            StatCard(
                title: "Average Weight",
                value: String(format: "%.1f kg", statistics.averageWeight),
                subtitle: "\(selectedTimeRange.displayName) avg",
                color: .orange,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            // Record Count Card
            StatCard(
                title: "Record Count",
                value: "\(statistics.recordCount)",
                subtitle: "records",
                color: .purple,
                icon: "list.number"
            )
        }
    }
    
    // MARK: - Weight Chart
    private var weightChart: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weight Trend")
                    .font(.headline)
                Spacer()
            }
            
            if filteredRecords.isEmpty {
                emptyChartView("No weight data", "Tap + to add a weight record")
            } else {
                Chart(filteredRecords) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.weight)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.weight)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(50)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight)) kg")
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - BMI Chart
    private var bmiChart: some View {
        VStack(spacing: 16) {
            HStack {
                Text("BMI Trend")
                    .font(.headline)
                Spacer()
            }
            
            if filteredRecords.isEmpty {
                emptyChartView("No BMI data", "Weight data is required to calculate BMI")
            } else {
                Chart(filteredRecords) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("BMI", BMICalculator.calculate(weight: record.weight, height: userHeight))
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("BMI", BMICalculator.calculate(weight: record.weight, height: userHeight))
                    )
                    .foregroundStyle(.green)
                    .symbolSize(50)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let bmi = value.as(Double.self) {
                                Text(String(format: "%.1f", bmi))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Recent Records
    private var recentRecords: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Records")
                    .font(.headline)
                Spacer()
            }
            
            if filteredRecords.isEmpty {
                emptyRecordsView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(filteredRecords.prefix(5))) { record in
                        WeightRecordRow(record: record, userHeight: userHeight)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Empty Views
    private func emptyChartView(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }
    
    private var emptyRecordsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 30))
                .foregroundColor(.gray)
            
            Text("No records")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start tracking your weight changes")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
    }
    
    // MARK: - Actions
    private func loadWeightRecords() {
        isLoading = true
        
        Task {
            do {
                // Load from backend API
                let historyResponse = try await APIService.shared.getWeightHistory(page: 1, pageSize: 100)
                
                // Convert API response to local WeightRecord models
                let records = historyResponse.records.map { apiRecord in
                    WeightRecord(
                        weight: apiRecord.weight,
                        date: parseDate(apiRecord.recorded_at),
                        notes: apiRecord.notes,
                        imagePath: apiRecord.image_path
                    )
                }
                
                await MainActor.run {
                    weightRecords = records
                    isLoading = false
                    print("DEBUG: Loaded \(records.count) weight records from backend")
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("ERROR: Failed to load weight records: \(error)")
                    // Fallback to sample data
                    generateSampleData()
                }
            }
        }
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.date(from: dateString) ?? Date()
    }
    
    private func generateSampleData() {
        let calendar = Calendar.current
        let today = Date()
        
        var records: [WeightRecord] = []
        let baseWeight = 65.0
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let weightVariation = Double.random(in: -0.5...0.5)
                let weight = baseWeight + weightVariation + (Double(i) * 0.1)
                let record = WeightRecord(weight: weight, date: date)
                records.append(record)
            }
        }
        
        weightRecords = records.sorted { $0.date > $1.date }
        print("DEBUG: Generated \(weightRecords.count) sample weight records")
    }
}

// MARK: - Time Range Enum
enum TimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case threeMonths = "threeMonths"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week:
            return "7天"
        case .month:
            return "1个月"
        case .threeMonths:
            return "3个月"
        case .year:
            return "1年"
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Weight Record Row Component
struct WeightRecordRow: View {
    let record: WeightRecord
    let userHeight: Double
    
    private var bmi: Double {
        BMICalculator.calculate(weight: record.weight, height: userHeight)
    }
    
    private var bmiCategory: BMICategory {
        BMICalculator.getBMICategory(bmi)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(record.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", record.weight)) kg")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Text("BMI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", bmi))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(bmiCategory.color)
                }
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Image(systemName: "note.text")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Preview
struct WeightChartView_Previews: PreviewProvider {
    static var previews: some View {
        WeightChartView()
    }
}

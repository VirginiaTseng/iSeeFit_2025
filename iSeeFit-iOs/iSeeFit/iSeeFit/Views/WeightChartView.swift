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
    @State private var timeRangeSliderValue: Double = 0.0 // 0: week, 1: month, 2: threeMonths, 3: year
    @State private var isSliding: Bool = false // 跟踪滑动状态
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
    
    // Weight chart Y-axis range - 显示更精确的波动
    private var weightYAxisRange: ClosedRange<Double> {
        guard !filteredRecords.isEmpty else { return 50...80 }
        
        let weights = filteredRecords.map { $0.weight }
        let minWeight = weights.min() ?? 60
        let maxWeight = weights.max() ?? 70
        let range = maxWeight - minWeight
        
        // 如果范围太小，至少显示5kg的范围
        let minRange: Double = 5.0
        let actualRange = max(range, minRange)
        
        // 在最小值和最大值基础上各扩展一点边距，让线条不贴边
        let margin = actualRange * 0.1
        let lowerBound = minWeight - margin
        let upperBound = maxWeight + margin
        
        return lowerBound...upperBound
    }
    
    // BMI chart Y-axis range - 显示更精确的波动
    private var bmiYAxisRange: ClosedRange<Double> {
        guard !filteredRecords.isEmpty else { return 18...25 }
        
        let bmis = filteredRecords.map { BMICalculator.calculate(weight: $0.weight, height: userHeight) }
        let minBMI = bmis.min() ?? 20
        let maxBMI = bmis.max() ?? 25
        let range = maxBMI - minBMI
        
        // 如果BMI范围太小，至少显示3的范围
        let minRange: Double = 3.0
        let actualRange = max(range, minRange)
        
        // 在最小值和最大值基础上各扩展一点边距
        let margin = actualRange * 0.1
        let lowerBound = minBMI - margin
        let upperBound = maxBMI + margin
        
        return lowerBound...upperBound
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Motivational Header
                    motivationalHeader
                    
                    // Add Weight Button
                    addWeightButton
                    
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
            .sheet(isPresented: $showAddWeight) {
                WeightInputView()
            }
            .onAppear {
                loadWeightRecords()
            }
        }
    }
    
    // MARK: - Motivational Header
    private var motivationalHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("💪 Keep Track, Stay Strong!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Every record brings you closer to your health goals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.purple.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
    
    // MARK: - Add Weight Button
    private var addWeightButton: some View {
        Button(action: {
            showAddWeight = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Record Your Weight")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Track your progress today")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.9),
                                Color.red.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        VStack(spacing: 16) {
            // 当前选择的时间范围显示
            HStack {
                Text("Time Range  📅")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(selectedTimeRange.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            // 磁性吸附滑动条 - 精确对齐版本
            VStack(spacing: 8) {
                // 滑动条
                Slider(value: $timeRangeSliderValue, in: 0...3) { editing in
                    isSliding = editing
                    
                    if editing {
                        // 滑动过程中实时更新（基于当前值，不吸附）
                        updateTimeRangeFromSliderDuringDrag()
                    } else {
                        // 滑动结束时吸附到最近的整数位置
                        snapToNearestPosition()
                    }
                }
                .accentColor(.blue)
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: timeRangeSliderValue)
                
                // 标签 - 使用相同的内边距确保完美对齐
                HStack {
                    Group {
                        Text("7 Days")
                            .font(.caption)
                            .fontWeight(isCurrentSelection(0) ? .semibold : .regular)
                            .foregroundColor(isCurrentSelection(0) ? .blue : .secondary)
                        
                        Spacer()
                        
                        Text("1 Month")
                            .font(.caption)
                            .fontWeight(isCurrentSelection(1) ? .semibold : .regular)
                            .foregroundColor(isCurrentSelection(1) ? .blue : .secondary)
                        
                        Spacer()
                        
                        Text("3 Months")
                            .font(.caption)
                            .fontWeight(isCurrentSelection(2) ? .semibold : .regular)
                            .foregroundColor(isCurrentSelection(2) ? .blue : .secondary)
                        
                        Spacer()
                        
                        Text("1 Year")
                            .font(.caption)
                            .fontWeight(isCurrentSelection(3) ? .semibold : .regular)
                            .foregroundColor(isCurrentSelection(3) ? .blue : .secondary)
                    }
                    .animation(.spring(response: 0.2, dampingFraction: 0.9), value: timeRangeSliderValue)
                }
                .padding(.horizontal, 16) // 与滑动条相同的padding
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.08),
                            Color.teal.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            // 初始化滑动条值
            timeRangeSliderValue = Double(TimeRange.allCases.firstIndex(of: selectedTimeRange) ?? 0)
        }
        .onChange(of: timeRangeSliderValue) { oldValue, newValue in
            // 如果不在滑动状态且值不是精确的整数，超快速修正
            if !isSliding && abs(newValue - round(newValue)) > 0.001 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    let correctedValue = round(newValue)
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.95)) {
                        self.timeRangeSliderValue = max(0, min(3, correctedValue))
                    }
                }
            }
        }
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
                color: .green,
                icon: "scalemass.fill"
            )
            
            // BMI Card
            StatCard(
                title: "BMI",
                value: String(format: "%.1f", statistics.bmi),
                subtitle: statistics.bmiCategory.description,
                color: .red,
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
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.weight)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(50)
                }
                .frame(height: 200)
                .chartYScale(domain: weightYAxisRange)
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
                                Text("\(String(format: "%.1f", weight)) kg")
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
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("BMI", BMICalculator.calculate(weight: record.weight, height: userHeight))
                    )
                    .foregroundStyle(.red)
                    .symbolSize(50)
                }
                .frame(height: 200)
                .chartYScale(domain: bmiYAxisRange)
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
    
    // MARK: - Helper Methods
    private func updateTimeRangeFromSlider() {
        let index = Int(round(timeRangeSliderValue))
        if index >= 0 && index < TimeRange.allCases.count {
            selectedTimeRange = TimeRange.allCases[index]
        }
    }
    
    // 滑动过程中的实时更新（不吸附，用于视觉反馈）
    private func updateTimeRangeFromSliderDuringDrag() {
        let nearestIndex = Int(round(timeRangeSliderValue))
        if nearestIndex >= 0 && nearestIndex < TimeRange.allCases.count {
            selectedTimeRange = TimeRange.allCases[nearestIndex]
        }
    }
    
    // 磁性吸附到最近的整数位置 - 快速精确版本
    private func snapToNearestPosition() {
        let nearestValue = round(timeRangeSliderValue)
        let clampedValue = max(0, min(3, nearestValue))
        
        // 计算吸附距离，用于调整动画参数
        let snapDistance = abs(timeRangeSliderValue - clampedValue)
        
        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 超快速吸附动画 - 更加跟手的响应速度
        let animationType: Animation = {
            if snapDistance > 0.7 {
                // 远距离吸附：快速有力的吸附，模拟强磁性
                return .spring(response: 0.25, dampingFraction: 0.8)
            } else if snapDistance > 0.3 {
                // 中距离吸附：迅速精确的吸附
                return .spring(response: 0.2, dampingFraction: 0.85)
            } else {
                // 近距离吸附：瞬间精确定位
                return .spring(response: 0.15, dampingFraction: 0.9)
            }
        }()
        
        withAnimation(animationType) {
            timeRangeSliderValue = clampedValue
        }
        
        // 确保最终精确位置 - 超短延迟时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // 无动画直接设置到精确位置，确保没有浮点数误差
            self.timeRangeSliderValue = clampedValue
        }
        
        // 更新选择的时间范围
        updateTimeRangeFromSlider()
    }
    
    // 判断是否为当前选择的选项
    private func isCurrentSelection(_ index: Int) -> Bool {
        if isSliding {
            // 滑动过程中基于最近的整数值来判断
            return Int(round(timeRangeSliderValue)) == index
        } else {
            // 静止时基于精确的整数值来判断
            return Int(timeRangeSliderValue) == index
        }
    }
    
    // MARK: - Actions
    private func loadWeightRecords() {
        isLoading = true
        
        Task {
            do {
                // Load local records first as immediate fallback
                let local = WeightLocalStore.shared.loadRecords()
                if !local.isEmpty {
                    await MainActor.run {
                        weightRecords = local
                        print("DEBUG: WeightChartView - loaded \(local.count) records from local store")
                    }
                }
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
                    if weightRecords.isEmpty {
                        // Fallback to sample data only if no local data
                        generateSampleData()
                    }
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
            return "7 Days"
        case .month:
            return "1 Month"
        case .threeMonths:
            return "3 Months"
        case .year:
            return "1 Year"
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
                    .foregroundColor(.white)
                    .font(.title2)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            ZStack {
                // 主背景 - 深色渐变
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.9),
                                color.opacity(1.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 玻璃反光效果 - 顶部高光
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.4), location: 0.0),
                                .init(color: Color.white.opacity(0.2), location: 0.3),
                                .init(color: Color.clear, location: 0.7),
                                .init(color: Color.clear, location: 1.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // 边框高光
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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

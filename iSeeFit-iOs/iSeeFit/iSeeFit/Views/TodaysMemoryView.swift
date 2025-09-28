//
//  TodaysMemoryView.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//

import SwiftUI

struct TodaysMemoryView: View {
    @State private var scrollOffset: CGFloat = 0
    @StateObject private var foodLocalStore = FoodLocalStore.shared
    @StateObject private var workoutRecorder = WorkoutRecorder.shared
    @StateObject private var recommendationService = RecommendationService.shared
    @State private var entries: [TodayEntry] = []
    @State private var workoutEntries: [TodayEntry] = []
    @State private var recommendation: String? = nil
    @State private var isLoadingRecommendation = false
    @State private var isRecommendationExpanded = false
    
    // 默认演示数据（当没有真实数据时显示）
    private let defaultEntries: [TodayEntry] = [
        TodayEntry(time: "08:12", title: "Breakfast", calories: 320, kind: .meal, image: nil, note: "Yogurt & fruits", protein: 15.0, carbs: 45.0, fat: 8.0),
        TodayEntry(time: "12:48", title: "Lunch", calories: 640, kind: .meal, image: nil, note: "Chicken salad", protein: 35.0, carbs: 25.0, fat: 12.0),
        TodayEntry(time: "18:30", title: "Workout", calories: 420, kind: .workout, image: nil, note: "Treadmill 40min", protein: nil, carbs: nil, fat: nil),
        TodayEntry(time: "20:05", title: "Dinner", calories: 510, kind: .meal, image: nil, note: "Shrimp & veggies", protein: 28.0, carbs: 30.0, fat: 18.0)
    ]

    private var intake: Int { entries.filter { $0.kind == .meal }.map { $0.calories }.reduce(0, +) }
    private var burn: Int { 
        let entriesBurn = entries.filter { $0.kind == .workout }.map { $0.calories }.reduce(0, +)
        let workoutBurn = workoutEntries.map { $0.calories }.reduce(0, +)
        print("DEBUG: TodaysMemoryView - burn calculation: entriesBurn=\(entriesBurn), workoutBurn=\(workoutBurn), total=\(entriesBurn + workoutBurn)")
        return entriesBurn + workoutBurn
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TodaysMemoryBkCard(externalScrollOffset: scrollOffset, burnedValue: burn)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 健康建议卡片 - 顶部显示
                        if let recommendation = recommendation {
                            ExpandableRecommendationCard(
                                advice: recommendation,
                                isExpanded: $isRecommendationExpanded
                            )
                            .padding(.top, 10)
                            .padding(.horizontal, 16)
                        } else if isLoadingRecommendation {
                            RecommendationLoadingCard()
                                .padding(.top, 10)
                                .padding(.horizontal, 16)
                        }
                        
                        TodayContentView(workoutEntries: workoutEntries)
                            .background(GeometryReader { geo in
                                Color.clear.onAppear {
                                    scrollOffset = geo.frame(in: .global).minY
                                }
                                .onChange(of: geo.frame(in: .global).minY) {
                                    scrollOffset = geo.frame(in: .global).minY
                                }
                            })
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 100) // 确保底部有足够空间
                    }
                }
                .background(Color.white)
            }
        }
        .ignoresSafeArea(.container, edges: .top) // 只忽略顶部安全区域
        .preferredColorScheme(.light) // 强制使用浅色模式
        .statusBarHidden() // 隐藏状态栏
        .onAppear {
            loadTodayEntries()
            loadTodayWorkoutEntries()
            loadRecommendation()
            print("DEBUG: TodaysMemoryView - onAppear entries: \(entries.count), workoutEntries: \(workoutEntries.count)")
        }
        .onChange(of: workoutRecorder.workoutHistory) {
            loadTodayWorkoutEntries()
            print("DEBUG: TodaysMemoryView - workoutHistory changed, workoutEntries: \(workoutEntries.count)")
        }
    }
    
    private func loadTodayEntries() {
        let todayRecords = foodLocalStore.getTodayRecords()
        
        if todayRecords.isEmpty {
            entries = defaultEntries
        } else {
            entries = todayRecords.map { record in
                let image: Image? = {
                    if let imagePath = record.imagePath,
                       let uiImage = ImageManager.shared.loadImage(from: imagePath) {
                        return Image(uiImage: uiImage)
                    }
                    return nil
                }()
                
                return TodayEntry(
                    time: formatTime(record.date),
                    title: getMealType(for: record.date),  // 显示餐次类型
                    calories: Int(record.calories),
                    kind: .meal,
                    image: image,
                    note: record.foodName,  // 食物名称作为备注
                    protein: record.protein,
                    carbs: record.carbs,
                    fat: record.fat
                )
            }
        }
    }
    
    private func getMealType(for date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 5..<11:
            return "Breakfast"
        case 11..<15:
            return "Lunch"
        case 15..<18:
            return "Snack"
        case 18..<22:
            return "Dinner"
        default:
            return "Snack"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 加载今天的训练记录
    private func loadTodayWorkoutEntries() {
        let todayWorkouts = workoutRecorder.workoutHistory.filter { workout in
            Calendar.current.isDateInToday(workout.startTime)
        }
        
        print("DEBUG: TodaysMemoryView - Found \(todayWorkouts.count) workout records for today")
        
        workoutEntries = todayWorkouts.map { workout in
            return TodayEntry(
                time: formatTime(workout.startTime),
                title: "Workout",
                calories: Int(workout.caloriesBurned),
                kind: .workout,
                image: nil,
                note: "\(workout.workoutType) - \(workout.formattedDuration)",
                protein: nil,
                carbs: nil,
                fat: nil
            )
        }
        // 打印映射后的训练条目，便于核对是否生成卡片数据
        for item in workoutEntries {
            print("DEBUG: TodaysMemoryView - workoutEntry => time: \(item.time), title: \(item.title), kcal: \(item.calories)")
        }
    }
    
    // 加载健康建议
    private func loadRecommendation() {
        Task {
            await MainActor.run {
                isLoadingRecommendation = true
            }
            
            // 提取今日食物名称
            let todayRecords = foodLocalStore.getTodayRecords()
            
            // 打印今日所有食物记录的详细信息
            print("DEBUG: TodaysMemoryView - 今日所有食物记录:")
            for (index, record) in todayRecords.enumerated() {
                print("  [\(index + 1)] 食物记录:")
                print("    - ID: \(record.id)")
                print("    - 食物名称: \(record.foodName)")
                print("    - 餐次类型: \(record.mealType)")
                print("    - 卡路里: \(record.calories)")
                print("    - 蛋白质: \(record.protein)g")
                print("    - 碳水化合物: \(record.carbs)g")
                print("    - 脂肪: \(record.fat)g")
                print("    - 日期: \(record.date)")
                print("    - 图片路径: \(record.imagePath ?? "无")")
                print("    - 备注: \(record.notes ?? "无")")
                print("    - 分析模式: \(record.analysisMode)")
                print("    - 检测到的食物: \(record.detectedFoods.count) 项")
                print("    ---")
            }
            
            // 选择最近的一个食物发送
            let latestFood = todayRecords.sorted { $0.date > $1.date }.first
            let foodNames = latestFood != nil ? [latestFood!.foodName] : []
            
            print("DEBUG: TodaysMemoryView - 选择最近的食物: \(foodNames)")
            
            // 请求健康建议
            let advice = await recommendationService.getAdvice(
                foodNames: foodNames,
                healthCondition: "stomach",
                promptStyle: "professional"
            )
            
            await MainActor.run {
                recommendation = advice
                isLoadingRecommendation = false
                print("DEBUG: TodaysMemoryView - Recommendation loaded: \(advice ?? "nil")")
            }
        }
    }
    }




// 新的内容视图，移除NavigationView和ScrollView以避免嵌套冲突
struct TodayContentView: View {
    let workoutEntries: [TodayEntry]  // 新增这行
    // 使用真实数据源
    @StateObject private var foodLocalStore = FoodLocalStore.shared
    @State private var entries: [TodayEntry] = []
    @State private var selectedEntry: TodayEntry? = nil
    @State private var showDetailView = false
    
    // 默认演示数据（当没有真实数据时显示）
    private let defaultEntries: [TodayEntry] = [
        TodayEntry(time: "08:12", title: "Breakfast", calories: 320, kind: .meal, image: nil, note: "Yogurt & fruits", protein: 15.0, carbs: 45.0, fat: 8.0),
        TodayEntry(time: "12:48", title: "Lunch", calories: 640, kind: .meal, image: nil, note: "Chicken salad", protein: 35.0, carbs: 25.0, fat: 12.0),
        TodayEntry(time: "18:30", title: "Workout", calories: 420, kind: .workout, image: nil, note: "Treadmill 40min", protein: nil, carbs: nil, fat: nil),
        TodayEntry(time: "20:05", title: "Dinner", calories: 510, kind: .meal, image: nil, note: "Shrimp & veggies", protein: 28.0, carbs: 30.0, fat: 18.0)
    ]

    private var intake: Int { entries.filter { $0.kind == .meal }.map { $0.calories }.reduce(0, +) }
    private var burn: Int { 
        let entriesBurn = entries.filter { $0.kind == .workout }.map { $0.calories }.reduce(0, +)
        let workoutBurn = workoutEntries.map { $0.calories }.reduce(0, +)
        print("DEBUG: TodaysMemoryView - burn calculation: entriesBurn=\(entriesBurn), workoutBurn=\(workoutBurn), total=\(entriesBurn + workoutBurn)")
        return entriesBurn + workoutBurn
    }
    
    var body: some View {
        VStack(spacing: 16) {
            header
            timeline
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .onAppear {
            loadTodayEntries()
        }
        .sheet(isPresented: $showDetailView) {
            if let entry = selectedEntry {
                FoodDetailView(entry: entry)
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 整合的营养横条组件
            summary
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    private var timeline: some View {
        VStack(spacing: 24) {
            // 合并食物和训练记录，按时间排序
            let allEntries = (entries + workoutEntries).sorted { $0.time < $1.time }
            
            ForEach(allEntries) { item in
                HStack(alignment: .top, spacing: 12) {
                    // 左列（餐饮）
                    Group {
                        if item.kind == .meal {
                            entryCard(item)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            Spacer(minLength: 0)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // 中线与时间
                    VStack(spacing: 6) {
                        Text(item.time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Circle().fill(item.kind == .meal ? Color.orange : Color.green)
                            .frame(width: 10, height: 10)
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(width: 2, height: 60)
                    }

                    // 右列（健身）
                    Group {
                        if item.kind == .workout {
                            entryCard(item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer(minLength: 0)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func entryCard(_ item: TodayEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title).font(.headline)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: item.kind == .meal ? "flame.fill" : "bolt.heart.fill")
                        .foregroundColor(item.kind == .meal ? .orange : .green)
                    Text("\(item.calories) kcal").font(.subheadline).bold()
                }
            }
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 110)
                .overlay(
                    ZStack {
                        if let img = item.image { 
                            img
                                .resizable()
                                .aspectRatio(5/3, contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        } else {
                            // 没有图片时的占位符背景
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: item.kind == .meal ? 
                                            [Color.orange.opacity(0.3), Color.pink.opacity(0.3)] :
                                            [Color.green.opacity(0.3), Color.blue.opacity(0.3)]
                                        ),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        // 文字叠加（优先显示食物名/训练描述，限制长度）
                        VStack {
                            Spacer()
                            Text(item.note ?? item.title)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.6))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
        }
        .onTapGesture {
            selectedEntry = item
            showDetailView = true
        }
    }

    private var summary: some View {
        // 整合的营养横条组件
        IntegratedNutritionBar(
            intakeValue: intake,
            burnedValue: burn,
            netValue: intake - burn
        )
    }
    
    private func loadTodayEntries() {
        let todayRecords = foodLocalStore.getTodayRecords()
        
        if todayRecords.isEmpty {
            entries = defaultEntries
        } else {
            entries = todayRecords.map { record in
                let image: Image? = {
                    if let imagePath = record.imagePath,
                       let uiImage = ImageManager.shared.loadImage(from: imagePath) {
                        return Image(uiImage: uiImage)
                    }
                    return nil
                }()
                
                return TodayEntry(
                    time: formatTime(record.date),
                    title: getMealType(for: record.date),  // 显示餐次类型
                    calories: Int(record.calories),
                    kind: .meal,
                    image: image,
                    note: record.foodName,  // 食物名称作为备注
                    protein: record.protein,
                    carbs: record.carbs,
                    fat: record.fat
                )
            }
        }
    }
    
    private func getMealType(for date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 5..<11:
            return "Breakfast"
        case 11..<15:
            return "Lunch"
        case 15..<18:
            return "Snack"
        case 18..<22:
            return "Dinner"
        default:
            return "Snack"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 营养横条组件
struct NutritionBar: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    let maxValue: Int
    let allowNegative: Bool
    
    init(title: String, value: Int, icon: String, color: Color, maxValue: Int, allowNegative: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.maxValue = max(maxValue, 1) // 避免除零错误
        self.allowNegative = allowNegative
    }
    
    private var progress: CGFloat {
        if allowNegative {
            // 对于Net值，可能为负数，需要特殊处理
            let absValue = abs(value)
            return min(CGFloat(absValue) / CGFloat(maxValue), 1.0)
        } else {
            return min(CGFloat(value) / CGFloat(maxValue), 1.0)
        }
    }
    
    private var barColor: Color {
        if allowNegative && value < 0 {
            return Color.red.opacity(0.7) // 负值使用红色
        }
        return color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 标题行
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(value) kcal")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景条
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)
                    
                    // 进度条
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [barColor.opacity(0.7), barColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// 双向营养横条组件
struct BidirectionalNutritionBar: View {
    let intakeValue: Int
    let burnedValue: Int
    
    private var maxValue: Int {
        max(intakeValue, burnedValue, 1) // 避免除零错误
    }
    
    private var intakeProgress: CGFloat {
        min(CGFloat(intakeValue) / CGFloat(maxValue), 1.0)
    }
    
    private var burnedProgress: CGFloat {
        min(CGFloat(burnedValue) / CGFloat(maxValue), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Intake")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Burned")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Image(systemName: "figure.run")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            // 数值显示行
            HStack {
                Text("\(intakeValue) kcal")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("\(burnedValue) kcal")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            // 双向进度条
            GeometryReader { geometry in
                ZStack {
                    // 背景条
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)
                    
                    HStack(spacing: 0) {
                        // 左侧 Intake 进度条
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.7), Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: (geometry.size.width * 0.5) * intakeProgress, height: 12)
                                .animation(.easeInOut(duration: 0.5), value: intakeProgress)
                        }
                        .frame(width: geometry.size.width * 0.5)
                        
                        // 中心分隔线
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 2, height: 16)
                        
                        // 右侧 Burned 进度条
                        HStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.7), Color.green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: (geometry.size.width * 0.5) * burnedProgress, height: 12)
                                .animation(.easeInOut(duration: 0.5), value: burnedProgress)
                            Spacer()
                        }
                        .frame(width: geometry.size.width * 0.5)
                    }
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// Net双向营养横条组件
struct NetNutritionBar: View {
    let netValue: Int
    let maxValue: Int
    
    private var progress: CGFloat {
        let absValue = abs(netValue)
        let safeMaxValue = max(maxValue, 1) // 避免除零错误
        return min(CGFloat(absValue) / CGFloat(safeMaxValue), 1.0)
    }
    
    private var isPositive: Bool {
        netValue >= 0
    }
    
    private var barColor: Color {
        isPositive ? Color.orange : Color.green
    }
    
    private var directionText: String {
        isPositive ? "Surplus" : "Deficit"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题行
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Net")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(directionText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(barColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(barColor.opacity(0.15))
                    .cornerRadius(4)
            }
            
            // 数值显示行
            HStack {
                if isPositive {
                    Text("\(netValue) kcal")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(barColor)
                    Spacer()
                } else {
                    Spacer()
                    Text("\(netValue) kcal")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(barColor)
                }
            }
            
            // 双向进度条
            GeometryReader { geometry in
                ZStack {
                    // 背景条
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)
                    
                    HStack(spacing: 0) {
                        // 左侧区域（正值 - Surplus）
                        HStack {
                            Spacer()
                            if isPositive {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange.opacity(0.7), Color.orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: (geometry.size.width * 0.5) * progress, height: 12)
                                    .animation(.easeInOut(duration: 0.5), value: progress)
                            }
                        }
                        .frame(width: geometry.size.width * 0.5)
                        
                        // 中心分隔线
                        Rectangle()
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: 2, height: 16)
                        
                        // 右侧区域（负值 - Deficit）
                        HStack {
                            if !isPositive {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.7), Color.green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: (geometry.size.width * 0.5) * progress, height: 12)
                                    .animation(.easeInOut(duration: 0.5), value: progress)
                            }
                            Spacer()
                        }
                        .frame(width: geometry.size.width * 0.5)
                    }
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// 整合的营养横条组件
struct IntegratedNutritionBar: View {
    let intakeValue: Int
    let burnedValue: Int
    let netValue: Int
    
    private var maxValue: Int {
        max(intakeValue, burnedValue, 1) // 避免除零错误
    }
    
    private var intakeProgress: CGFloat {
        min(CGFloat(intakeValue) / CGFloat(maxValue), 1.0)
    }
    
    private var burnedProgress: CGFloat {
        min(CGFloat(burnedValue) / CGFloat(maxValue), 1.0)
    }
    
    private var netProgress: CGFloat {
        let absValue = abs(netValue)
        let safeMaxValue = max(maxValue, 1)
        return min(CGFloat(absValue) / CGFloat(safeMaxValue), 1.0)
    }
    
    private var isNetPositive: Bool {
        netValue >= 0
    }
    
    private var netBarColor: Color {
        isNetPositive ? Color.orange : Color.green
    }
    
    private var netDirectionText: String {
        isNetPositive ? "Surplus" : "Deficit"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 上半部分：Intake vs Burned
            VStack(alignment: .leading, spacing: 8) {
                // 标题行
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Intake")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Burned")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Image(systemName: "figure.run")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                // 数值显示行
                HStack {
                    Text("\(intakeValue) kcal")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Text("\(burnedValue) kcal")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                // Intake vs Burned 双向进度条
                GeometryReader { geometry in
                    ZStack {
                        // 背景条
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)
                        
                        HStack(spacing: 0) {
                            // 左侧 Intake 进度条
                            HStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange.opacity(0.7), Color.orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: (geometry.size.width * 0.5) * intakeProgress, height: 12)
                                    .animation(.easeInOut(duration: 0.5), value: intakeProgress)
                            }
                            .frame(width: geometry.size.width * 0.5)
                            
                            // 中心分隔线
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 2, height: 16)
                            
                            // 右侧 Burned 进度条
                            HStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green.opacity(0.7), Color.green],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: (geometry.size.width * 0.5) * burnedProgress, height: 12)
                                    .animation(.easeInOut(duration: 0.5), value: burnedProgress)
                                Spacer()
                            }
                            .frame(width: geometry.size.width * 0.5)
                        }
                    }
                }
                .frame(height: 12)
            }
            
            // 下半部分：Net 横条
            VStack(alignment: .leading, spacing: 8) {
                // Net 数值显示行
                HStack {
                    if isNetPositive {
                        Text("\(netValue) kcal")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(netBarColor)
                        Spacer()
                        Text(netDirectionText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(netBarColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(netBarColor.opacity(0.15))
                            .cornerRadius(4)
                    } else {
                        Text(netDirectionText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(netBarColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(netBarColor.opacity(0.15))
                            .cornerRadius(4)
                        Spacer()
                        Text("\(netValue) kcal")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(netBarColor)
                    }
                }
                
                // Net 双向进度条
                GeometryReader { geometry in
                    ZStack {
                        // 背景条
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)
                        
                        HStack(spacing: 0) {
                            // 左侧区域（正值 - Surplus）
                            HStack {
                                Spacer()
                                if isNetPositive {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange.opacity(0.7), Color.orange],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: (geometry.size.width * 0.5) * netProgress, height: 12)
                                        .animation(.easeInOut(duration: 0.5), value: netProgress)
                                }
                            }
                            .frame(width: geometry.size.width * 0.5)
                            
                            // 中心分隔线
                            Rectangle()
                                .fill(Color.blue.opacity(0.6))
                                .frame(width: 2, height: 16)
                            
                            // 右侧区域（负值 - Deficit）
                            HStack {
                                if !isNetPositive {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.green.opacity(0.7), Color.green],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: (geometry.size.width * 0.5) * netProgress, height: 12)
                                        .animation(.easeInOut(duration: 0.5), value: netProgress)
                                }
                                Spacer()
                            }
                            .frame(width: geometry.size.width * 0.5)
                        }
                    }
                }
                .frame(height: 12)
                
                // Net 标题和图标 - 居中显示在横条下方
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text("Net")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Recommendation Card Components
struct ExpandableRecommendationCard: View {
    let advice: String
    @Binding var isExpanded: Bool
    
    private var previewText: String {
        let words = advice.components(separatedBy: " ")
        if words.count <= 10 {
            return advice
        }
        return words.prefix(10).joined(separator: " ") + "..."
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("Health Advice")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.title3)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
            }
            
            Text(isExpanded ? advice : previewText)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 3)
                .multilineTextAlignment(.leading)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}

struct RecommendationCard: View {
    let advice: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("Health Advice")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(advice)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct RecommendationLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                
                Text("Health Advice")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading personalized advice...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct TodaysMemoryView_Previews: PreviewProvider {
    static var previews: some View {
        TodaysMemoryView()
    }
}

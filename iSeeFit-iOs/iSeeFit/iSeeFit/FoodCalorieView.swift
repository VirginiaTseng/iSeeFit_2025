//
//  FoodCalorieView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import SwiftUI
import UIKit

struct FoodCalorieView: View {
    @StateObject private var foodAnalysisManager = FoodAnalysisManager()
    @StateObject private var apiService = APIService.shared
    @State private var selectedImage: UIImage?
    @State private var showPicker = false
    @State private var useCamera = false
    @State private var mealType = "breakfast"
    @State private var portionSize = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    @State private var showLoginSheet = false
    @State private var showAnalysisSettings = false
    @State private var portionMultiplier: Double = 1.0
    @State private var cardOffset: CGFloat = 0
    @State private var isCardExpanded: Bool = true
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            backgroundView
            mainContentView
            statusOverlays
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(image: $selectedImage, completion: { image in
                if let image = image {
                    Task {
                        await foodAnalysisManager.analyze(image: image)
                    }
                }
            }, sourceType: useCamera ? .camera : .photoLibrary)
        }
        .sheet(isPresented: $showAnalysisSettings) {
            AnalysisSettingsView(foodAnalysisManager: foodAnalysisManager)
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
        }
        .alert("Save Result", isPresented: $showSaveAlert) {
            Button("OK") { }
        } message: {
            Text(saveMessage)
        }
        .navigationTitle("Food Calories")
    }
    
    // MARK: - Save Meal Record
    private func saveMealRecord() {
        guard foodAnalysisManager.hasResults else { return }
        
        isSaving = true
        
        Task {
            do {
                // Create food name from detected items
                let foodNames = foodAnalysisManager.detectedFoods.map { $0.food_detected }
                let foodName = foodNames.joined(separator: ", ")
                
                // Create notes with detailed information
                var detailedNotes = notes.isEmpty ? "" : notes + "\n\n"
                detailedNotes += "Analysis Details:\n"
                detailedNotes += "• Mode: \(foodAnalysisManager.analysisMode)\n"
                detailedNotes += "• Total Portion: \(String(format: "%.1f", foodAnalysisManager.totalPortion))g\n"
                detailedNotes += "• Detected items:\n"
                for item in foodAnalysisManager.detectedFoods {
                    detailedNotes += "  - \(item.food_detected) (\(String(format: "%.1f", item.portion_g))g, \(String(format: "%.0f%%", item.confidence * 100)) confidence)\n"
                }
                
                if let analysisNotes = foodAnalysisManager.analysisNotes, !analysisNotes.isEmpty {
                    detailedNotes += "\nAI Notes: \(analysisNotes)\n"
                }
                
                // Convert FoodAnalysisItem to DetectedFoodItem for local storage
                let detectedFoods = foodAnalysisManager.detectedFoods.map { item in
                    DetectedFoodItem(
                        foodName: item.food_detected,
                        portionGrams: item.portion_g,
                        confidence: item.confidence,
                        calories: item.calories_kcal,
                        protein: item.protein_g,
                        carbs: item.carbs_g,
                        fat: item.fat_g,
                        source: item.source
                    )
                }
                
                // Create local food record first (with portion multiplier applied)
                let localRecord = FoodRecord(
                    mealType: mealType,
                    foodName: foodName,
                    calories: foodAnalysisManager.totalCalories * portionMultiplier,
                    protein: foodAnalysisManager.totalProtein * portionMultiplier,
                    carbs: foodAnalysisManager.totalCarbs * portionMultiplier,
                    fat: foodAnalysisManager.totalFat * portionMultiplier,
                    portionSize: portionSize.isEmpty ? nil : portionSize,
                    notes: detailedNotes.isEmpty ? nil : detailedNotes,
                    imagePath: nil, // Will be set after saving image
                    analysisMode: foodAnalysisManager.analysisMode,
                    detectedFoods: detectedFoods
                )
                
                // Save image locally if available
                var imagePath: String? = nil
                if let image = selectedImage {
                    imagePath = ImageManager.shared.saveFoodImage(image, recordId: localRecord.id)
                }
                
                // Update local record with image path
                let finalLocalRecord = FoodRecord(
                    mealType: localRecord.mealType,
                    foodName: localRecord.foodName,
                    calories: localRecord.calories,
                    protein: localRecord.protein,
                    carbs: localRecord.carbs,
                    fat: localRecord.fat,
                    portionSize: localRecord.portionSize,
                    notes: localRecord.notes,
                    imagePath: imagePath,
                    analysisMode: localRecord.analysisMode,
                    detectedFoods: localRecord.detectedFoods,
                    date: localRecord.date
                )
                
                // Save to local storage first (offline-friendly)
                FoodLocalStore.shared.addRecord(finalLocalRecord)
                print("DEBUG: FoodCalorieView - saved local record: \(foodName) (\(foodAnalysisManager.totalCalories)kcal)")
                
                // Debug logging
                print("🔍 Saving meal record with data:")
                print("  - Meal Type: \(mealType)")
                print("  - Food Name: \(foodName)")
                print("  - Calories: \(foodAnalysisManager.totalCalories)")
                print("  - Protein: \(foodAnalysisManager.totalProtein)")
                print("  - Carbs: \(foodAnalysisManager.totalCarbs)")
                print("  - Fat: \(foodAnalysisManager.totalFat)")
                print("  - Portion Size: \(portionSize.isEmpty ? "nil" : portionSize)")
                print("  - Has Image: \(selectedImage != nil)")
                print("  - Image Path: \(imagePath ?? "nil")")
                print("  - Is Authenticated: \(apiService.isAuthenticated)")
                
                // Save to backend API if authenticated
                if apiService.isAuthenticated {
                    let mealRecord = try await apiService.createMealRecord(
                        mealType: mealType,
                        foodName: foodName,
                        calories: foodAnalysisManager.totalCalories * portionMultiplier,
                        protein: foodAnalysisManager.totalProtein * portionMultiplier,
                        carbs: foodAnalysisManager.totalCarbs * portionMultiplier,
                        fat: foodAnalysisManager.totalFat * portionMultiplier,
                        portionSize: portionSize.isEmpty ? nil : portionSize,
                        notes: detailedNotes.isEmpty ? nil : detailedNotes,
                        image: selectedImage
                    )
                    
                    print("DEBUG: FoodCalorieView - saved to backend: \(mealRecord.food_name) (ID: \(mealRecord.id))")
                } else {
                    print("DEBUG: FoodCalorieView - not authenticated, saved locally only")
                }
                
                await MainActor.run {
                    isSaving = false
                    let authStatus = apiService.isAuthenticated ? " (synced to cloud)" : " (local only)"
                    saveMessage = "Meal record saved successfully\(authStatus)!\nFood: \(foodName)\nCalories: \(Int(foodAnalysisManager.totalCalories * portionMultiplier))"
                    showSaveAlert = true
                    
                    // Clear form
                    selectedImage = nil
                    foodAnalysisManager.clearResults()
                    portionSize = ""
                    notes = ""
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    // Enhanced error message with more details
                    var errorDetails = error.localizedDescription
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            errorDetails = "Authentication failed. Please login again."
                        case .networkError(let message):
                            errorDetails = "Network error: \(message)"
                        case .serverError(let code):
                            errorDetails = "Server error (\(code)). Please try again later."
                        case .decodingError:
                            errorDetails = "Failed to parse server response. Please try again."
                        default:
                            errorDetails = "Unknown error: \(error.localizedDescription)"
                        }
                    }
                    saveMessage = "Failed to save meal record: \(errorDetails)"
                    showSaveAlert = true
                }
            }
        }
    }
    
    // MARK: - Sub Views
    private var backgroundView: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            topActionButtons
            Spacer()
            bottomInformationCard
        }
    }
    
    private var topActionButtons: some View {
        HStack {
            Spacer()
            HStack(spacing: 12) {
                Button(action: {
                    useCamera = false
                    showPicker = true
                }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    useCamera = true
                    showPicker = true
                }) {
                    Image(systemName: "camera")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    showAnalysisSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 20)
    }
    
    private var bottomInformationCard: some View {
        VStack(spacing: 0) {
            dragHandle
            cardContent
        }
        .background(glassMorphismBackground)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
        .offset(y: cardOffset + dragOffset)
        .gesture(cardDragGesture)
        .onTapGesture {
            toggleCardExpansion()
        }
    }
    
    private var dragHandle: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
        }
    }
    
    private var cardContent: some View {
        Group {
            if !isCardExpanded {
                collapsedCardContent
            } else {
                expandedCardContent
            }
        }
    }
    
    private var collapsedCardContent: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedImage != nil ? getFoodName() : "Select a food photo")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(Int(foodAnalysisManager.totalCalories * portionMultiplier))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            quickActionButtons
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var expandedCardContent: some View {
        VStack(spacing: 0) {
            foodNameAndPortion
            analysisResults
            actionButtons
        }
    }
    
    private var foodNameAndPortion: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedImage != nil ? getFoodName() : "Select a food photo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                portionSelector
            }
            
            caloriesAndMacronutrients
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var portionSelector: some View {
        HStack(spacing: 8) {
            Button(action: { adjustPortion(-1) }) {
                Image(systemName: "minus")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            
            Text("\(Int(portionMultiplier))")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(minWidth: 30)
            
            Button(action: { adjustPortion(1) }) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
    }
    
    private var caloriesAndMacronutrients: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(Int(foodAnalysisManager.totalCalories * portionMultiplier))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            macronutrientCards
        }
    }
    
    private var macronutrientCards: some View {
        HStack(spacing: 8) {
            MacronutrientCard(
                title: "Protein",
                value: "\(String(format: "%.0f", foodAnalysisManager.totalProtein * portionMultiplier))g",
                icon: "fork.knife",
                color: .red
            )
            
            MacronutrientCard(
                title: "Carbs",
                value: "\(String(format: "%.0f", foodAnalysisManager.totalCarbs * portionMultiplier))g",
                icon: "leaf",
                color: .green
            )
            
            MacronutrientCard(
                title: "Fat",
                value: "\(String(format: "%.0f", foodAnalysisManager.totalFat * portionMultiplier))g",
                icon: "drop",
                color: .blue
            )
        }
    }
    
    private var analysisResults: some View {
        Group {
            if foodAnalysisManager.hasResults {
                VStack(alignment: .leading, spacing: 12) {
                    detectedFoods
                    analysisNotes
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
    }
    
    private var detectedFoods: some View {
        Group {
            if !foodAnalysisManager.detectedFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Foods")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(foodAnalysisManager.detectedFoods.enumerated()), id: \.offset) { index, item in
                        CompactFoodItemView(item: item, index: index)
                    }
                }
            }
        }
    }
    
    private var analysisNotes: some View {
        Group {
            if let notes = foodAnalysisManager.analysisNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis Notes")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            saveButton
            analyzeButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    private var saveButton: some View {
        Button(action: saveMealRecord) {
            HStack {
                Image(systemName: "bookmark")
                Text("Save")
            }
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(!foodAnalysisManager.hasResults || isSaving)
    }
    
    private var analyzeButton: some View {
        Button(action: {
            if let image = selectedImage {
                Task {
                    await foodAnalysisManager.analyze(image: image)
                }
            }
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("Analyze")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
        }
        .disabled(selectedImage == nil || foodAnalysisManager.isAnalyzing)
    }
    
    private var quickActionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                if let image = selectedImage {
                    Task {
                        await foodAnalysisManager.analyze(image: image)
                    }
                }
            }) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Circle())
            }
            .disabled(selectedImage == nil || foodAnalysisManager.isAnalyzing)
            
            Button(action: saveMealRecord) {
                Image(systemName: "bookmark")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .disabled(!foodAnalysisManager.hasResults || isSaving)
        }
    }
    
    private var glassMorphismBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var cardDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if isCardExpanded && value.translation.height > 0 {
                    dragOffset = value.translation.height
                } else if !isCardExpanded && value.translation.height < 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                handleDragEnd(value)
            }
    }
    
    private var statusOverlays: some View {
        Group {
            if foodAnalysisManager.isAnalyzing {
                analysisStatusOverlay
            }
            
            if let errorMessage = foodAnalysisManager.errorMessage {
                errorMessageOverlay(errorMessage)
            }
        }
    }
    
    private var analysisStatusOverlay: some View {
        VStack {
            Spacer()
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Analyzing food...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(20)
            .padding(.bottom, isCardExpanded ? 200 : 100)
        }
    }
    
    private func errorMessageOverlay(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.8))
                .cornerRadius(12)
                .padding(.bottom, isCardExpanded ? 200 : 100)
        }
    }
    
    // MARK: - Helper Methods
    private func getFoodName() -> String {
        if foodAnalysisManager.hasResults && !foodAnalysisManager.detectedFoods.isEmpty {
            let foodNames = foodAnalysisManager.detectedFoods.map { $0.food_detected }
            return foodNames.joined(separator: ", ")
        }
        return "Food Analysis"
    }
    
    private func adjustPortion(_ delta: Int) {
        let newValue = portionMultiplier + Double(delta)
        if newValue >= 0.5 && newValue <= 5.0 {
            portionMultiplier = newValue
        }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value) {
        let threshold: CGFloat = 50
        
        if isCardExpanded {
            // Currently expanded - check if should collapse
            if value.translation.height > threshold || value.predictedEndTranslation.height > 100 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isCardExpanded = false
                    cardOffset = 0
                    dragOffset = 0
                }
            } else {
                // Snap back to expanded
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
        } else {
            // Currently collapsed - check if should expand
            if value.translation.height < -threshold || value.predictedEndTranslation.height < -100 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isCardExpanded = true
                    cardOffset = 0
                    dragOffset = 0
                }
            } else {
                // Snap back to collapsed
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
        }
    }
    
    private func toggleCardExpansion() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isCardExpanded.toggle()
            cardOffset = 0
            dragOffset = 0
        }
    }
}

// MARK: - Supporting Views
struct FoodItemCard: View {
    let item: FoodAnalysisItem
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index + 1). \(item.food_detected)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(String(format: "%.0f%%", item.confidence * 100))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(8)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%.1f", item.portion_g))g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.0f", item.calories_kcal)) kcal")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("P: \(String(format: "%.1f", item.protein_g))g")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("C: \(String(format: "%.1f", item.carbs_g))g")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("F: \(String(format: "%.1f", item.fat_g))g")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                Text("Source: \(item.source)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var confidenceColor: Color {
        if item.confidence >= 0.8 {
            return .green
        } else if item.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct NutritionSummaryCard: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let portion: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    NutritionItemView(
                        title: "Total Portion",
                        value: "\(String(format: "%.1f", portion))g",
                        color: .primary
                    )
                    NutritionItemView(
                        title: "Calories",
                        value: "\(String(format: "%.0f", calories)) kcal",
                        color: .orange
                    )
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    NutritionItemView(
                        title: "Protein",
                        value: "\(String(format: "%.1f", protein))g",
                        color: .blue
                    )
                    NutritionItemView(
                        title: "Carbs",
                        value: "\(String(format: "%.1f", carbs))g",
                        color: .green
                    )
                    NutritionItemView(
                        title: "Fat",
                        value: "\(String(format: "%.1f", fat))g",
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.systemGray4), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct NutritionItemView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct AnalysisSettingsView: View {
    @ObservedObject var foodAnalysisManager: FoodAnalysisManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Analysis Settings")) {
                    Toggle("Use AI Portion Estimation", isOn: $foodAnalysisManager.useAIPortions)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manual Portion Size (grams)")
                            .font(.subheadline)
                        Slider(value: $foodAnalysisManager.portionSlider, in: 50...1000, step: 25)
                        Text("\(Int(foodAnalysisManager.portionSlider))g")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manual Override (optional)")
                            .font(.subheadline)
                        TextField("e.g., roast chicken", text: $foodAnalysisManager.manualOverride)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section(header: Text("Service Status")) {
                    HStack {
                        Text("OpenAI Enabled")
                        Spacer()
                        Text(foodAnalysisManager.isOpenAIEnabled ? "Yes" : "No")
                            .foregroundColor(foodAnalysisManager.isOpenAIEnabled ? .green : .red)
                    }
                    
                    if let modelName = foodAnalysisManager.modelName {
                        HStack {
                            Text("Model")
                            Spacer()
                            Text(modelName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Fallback Classifier")
                        Spacer()
                        Text(foodAnalysisManager.fallbackClassifier)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Analysis Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct MacronutrientCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
    }
}

struct CompactFoodItemView: View {
    let item: FoodAnalysisItem
    let index: Int
    
    var body: some View {
        HStack {
            Text("\(index + 1). \(item.food_detected)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(String(format: "%.1f", item.portion_g))g")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.0f", item.calories_kcal)) kcal")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text(String(format: "%.0f%%", item.confidence * 100))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var confidenceColor: Color {
        if item.confidence >= 0.8 {
            return .green
        } else if item.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct FoodCalorieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { FoodCalorieView() }
    }
}



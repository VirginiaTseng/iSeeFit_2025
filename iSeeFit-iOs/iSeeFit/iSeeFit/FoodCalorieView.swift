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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .cornerRadius(12)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                            .frame(height: 200)
                        Text("No Image Selected")
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Button("Choose Photo") {
                        useCamera = false
                        showPicker = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Take Photo") {
                        useCamera = true
                        showPicker = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Settings") {
                        showAnalysisSettings = true
                    }
                    .buttonStyle(.bordered)
                }

                // Analysis Status
                if foodAnalysisManager.isAnalyzing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing food...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                }
                
                // Analysis Results
                if foodAnalysisManager.hasResults {
                    VStack(alignment: .leading, spacing: 16) {
                        // Analysis Mode Info
                        HStack {
                            Image(systemName: foodAnalysisManager.isOpenAIEnabled ? "brain.head.profile" : "cpu")
                                .foregroundColor(.blue)
                            Text("Analysis Mode: \(foodAnalysisManager.analysisMode)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        // Detected Foods
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detected Foods")
                                .font(.headline)
                            
                            ForEach(Array(foodAnalysisManager.detectedFoods.enumerated()), id: \.offset) { index, item in
                                FoodItemCard(item: item, index: index)
                            }
                        }
                        
                        // Nutrition Summary
                        NutritionSummaryCard(
                            calories: foodAnalysisManager.totalCalories,
                            protein: foodAnalysisManager.totalProtein,
                            carbs: foodAnalysisManager.totalCarbs,
                            fat: foodAnalysisManager.totalFat,
                            portion: foodAnalysisManager.totalPortion
                        )
                        
                        // Analysis Notes
                        if let notes = foodAnalysisManager.analysisNotes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Analysis Notes")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Error Message
                if let errorMessage = foodAnalysisManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Meal Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Type")
                        .font(.headline)
                    Picker("Meal Type", selection: $mealType) {
                        Text("Breakfast").tag("breakfast")
                        Text("Lunch").tag("lunch")
                        Text("Dinner").tag("dinner")
                        Text("Snack").tag("snack")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Additional Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Additional Information")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portion Size (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("e.g., 1 bowl, 2 slices", text: $portionSize)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Add any notes about this meal", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                }
                
                // Save Button
                if foodAnalysisManager.hasResults {
                    Button(action: saveMealRecord) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text(isSaving ? "Saving..." : "Save Meal Record")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(apiService.isAuthenticated ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving || !apiService.isAuthenticated)
                }
                
                // Authentication Status
                if !apiService.isAuthenticated {
                    VStack(spacing: 8) {
                        Text("Please login to save meal records")
                            .foregroundColor(.secondary)
                        Button("Login") {
                            showLoginSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                }

            }
            .padding()
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
                
                let mealRecord = try await apiService.createMealRecord(
                    mealType: mealType,
                    foodName: foodName,
                    calories: foodAnalysisManager.totalCalories,
                    protein: foodAnalysisManager.totalProtein,
                    carbs: foodAnalysisManager.totalCarbs,
                    fat: foodAnalysisManager.totalFat,
                    portionSize: portionSize.isEmpty ? nil : portionSize,
                    notes: detailedNotes.isEmpty ? nil : detailedNotes,
                    image: selectedImage
                )
                
                await MainActor.run {
                    isSaving = false
                    saveMessage = "Meal record saved successfully!\nFood: \(mealRecord.food_name)\nCalories: \(Int(mealRecord.calories))"
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
                    saveMessage = "Failed to save meal record: \(error.localizedDescription)"
                    showSaveAlert = true
                }
            }
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

struct FoodCalorieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { FoodCalorieView() }
    }
}



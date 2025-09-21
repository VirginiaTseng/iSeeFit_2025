//
//  FoodCalorieView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import SwiftUI
import UIKit

struct FoodCalorieView: View {
    @StateObject private var manager = FoodRecognitionManager()
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
                }

                if !manager.items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected Items")
                            .font(.headline)
                        ForEach(manager.items) { item in
                            HStack {
                                Text(item.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(String(format: "%.0f%%", item.confidence * 100))
                                    .foregroundColor(.secondary)
                                Text("· \(item.calories) kcal")
                                    .fontWeight(.semibold)
                            }
                            .padding(10)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }

                HStack {
                    Text("Total Calories")
                        .font(.headline)
                    Spacer()
                    Text("\(manager.totalCalories) kcal")
                        .font(.title3).bold()
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
                if !manager.items.isEmpty {
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

                if let error = manager.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(image: $selectedImage, completion: { image in
                if let image = image {
                    manager.analyze(image: image)
                }
            }, sourceType: useCamera ? .camera : .photoLibrary)
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
        guard !manager.items.isEmpty else { return }
        
        isSaving = true
        
        Task {
            do {
                // Calculate total nutrition values
//                let totalProtein = manager.items.reduce(into: 0.0) { result, item in
//                    result += item.protein
//                }
//                let totalCarbs = manager.items.reduce(into: 0.0) { result, item in
//                    result += item.carbs
//                }
//                let totalFat = manager.items.reduce(into: 0.0) { result, item in
//                    result += item.fat
//                }
                
                // Create food name from detected items
                let foodNames = manager.items.map { $0.name }
                let foodName = foodNames.joined(separator: ", ")
                
                // Create notes with detailed information
                var detailedNotes = notes.isEmpty ? "" : notes + "\n\n"
                detailedNotes += "Detected items:\n"
                for item in manager.items {
                    detailedNotes += "• \(item.name) (\(String(format: "%.0f%%", item.confidence * 100)) confidence)\n"
                }
                
                let mealRecord = try await apiService.createMealRecord(
                    mealType: mealType,
                    foodName: foodName,
                    calories: Double(manager.totalCalories),
//                    protein: totalProtein,
//                    carbs: totalCarbs,
//                    fat: totalFat,
                    portionSize: portionSize.isEmpty ? nil : portionSize,
                    notes: detailedNotes.isEmpty ? nil : detailedNotes,
                  //  image: selectedImage
                )
                
                await MainActor.run {
                    isSaving = false
                    saveMessage = "Meal record saved successfully!\nFood: \(mealRecord.food_name)\nCalories: \(Int(mealRecord.calories))"
                    showSaveAlert = true
                    
                    // Clear form
                    selectedImage = nil
                    manager.items.removeAll()
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

struct FoodCalorieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { FoodCalorieView() }
    }
}



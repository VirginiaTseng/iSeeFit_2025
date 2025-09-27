//
//  WeightInputView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-19.
//

import SwiftUI
import UIKit

struct WeightInputView: View {
    @StateObject private var apiService = APIService.shared
    @State private var weight: String = ""
    @State private var selectedDate = Date()
    @State private var notes: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var useCamera = false
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSuccess = false
    
    // User height for BMI calculation
    private var userHeight: Double {
        apiService.currentUser?.height ?? 170.0 // Default height if not available
    }
    
    // BMI calculation
    private var bmi: Double {
        guard let weightValue = Double(weight), weightValue > 0 else { return 0 }
        return BMICalculator.calculate(weight: weightValue, height: userHeight)
    }
    
    // BMI category
    private var bmiCategory: BMICategory {
        BMICalculator.getBMICategory(bmi)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard
                    
                    // Weight Input Card
                    weightInputCard
                    
                    // BMI Display Card
                    if !weight.isEmpty && Double(weight) != nil {
                        bmiDisplayCard
                    }
                    
                    // Image Selection Card
                    imageSelectionCard
                    
                    // Notes Card
                    notesCard
                    
                    // Save Button
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.large)
            .alert("Notice", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .alert("Saved Successfully", isPresented: $showSuccess) {
                Button("OK") {
                    resetForm()
                }
            } message: {
                Text("Weight record has been saved")
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    image: $selectedImage,
                    completion: { image in
                        selectedImage = image
                    },
                    sourceType: useCamera ? .camera : .photoLibrary
                )
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "scalemass.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Record Today's Weight")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Stay healthy, start by tracking")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    // MARK: - Weight Input Card
    private var weightInputCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weight")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                TextField("Enter weight", text: $weight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .multilineTextAlignment(.center)
                
                Text("kg")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            // Date Picker
            DatePicker("Record Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - BMI Display Card
    private var bmiDisplayCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("BMI Index")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%.1f", bmi))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(bmiCategory.color)
                    
                    Text(bmiCategory.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // BMI Category Icon
                Image(systemName: bmiIcon)
                    .font(.system(size: 40))
                    .foregroundColor(bmiCategory.color)
            }
            
            // BMI Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(bmiCategory.color)
                        .frame(width: bmiProgressWidth(geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Image Selection Card
    private var imageSelectionCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weight Photo")
                    .font(.headline)
                Spacer()
            }
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .overlay(
                        Button(action: {
                            selectedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "camera")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            Text("Add weight photo")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            HStack(spacing: 12) {
                Button("Choose Photo") {
                    useCamera = false
                    showImagePicker = true
                }
                .buttonStyle(.bordered)
                
                Button("Take Photo") {
                    useCamera = true
                    showImagePicker = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Notes Card
    private var notesCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
            }
            
            TextField("Add notes (optional)", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveWeightRecord) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isSaving ? "Saving..." : "Save Weight Record")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isValidInput ? Color.blue : Color.gray)
            )
        }
        .disabled(!isValidInput || isSaving)
    }
    
    // MARK: - Computed Properties
    private var isValidInput: Bool {
        guard let weightValue = Double(weight) else { return false }
        return weightValue > 0 && weightValue < 500 // Reasonable weight range
    }
    
    private var bmiIcon: String {
        switch bmiCategory {
        case .underweight:
            return "arrow.down.circle.fill"
        case .normal:
            return "checkmark.circle.fill"
        case .overweight:
            return "exclamationmark.triangle.fill"
        case .obese:
            return "exclamationmark.octagon.fill"
        }
    }
    
    private func bmiProgressWidth(_ totalWidth: CGFloat) -> CGFloat {
        let progress = min(max(bmi / 30.0, 0), 1) // Normalize BMI to 0-30 range
        return totalWidth * progress
    }
    
    // MARK: - Actions
    private func saveWeightRecord() {
        guard let weightValue = Double(weight) else { return }
        
        isSaving = true
        
        Task {
           
                // Save locally first (offline-friendly)
                let localRecord = WeightRecord(
                    weight: weightValue,
                    date: selectedDate,
                    notes: notes.isEmpty ? nil : notes,
                    imagePath: nil
                )
                WeightLocalStore.shared.addRecord(localRecord)
                print("DEBUG: WeightInputView - saved local record: \(weightValue)kg @ \(selectedDate)")
                
            do {
                // Save to backend API
                let weightRecord = try await apiService.createWeightRecord(
                    weight: weightValue,
                    height: userHeight,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    isSaving = false
                    showSuccess = true
                    print("DEBUG: Weight record saved to backend - ID: \(weightRecord.id), Weight: \(weightValue)kg")
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    // alertMessage = "保存失败: \(error.localizedDescription)"
                    // showAlert = true
                    print("ERROR: Failed to save weight record: \(error)")
                }
            }
        }
    }
    
    private func resetForm() {
        weight = ""
        selectedDate = Date()
        notes = ""
        selectedImage = nil
    }
}

// MARK: - Preview
struct WeightInputView_Previews: PreviewProvider {
    static var previews: some View {
        WeightInputView()
    }
}

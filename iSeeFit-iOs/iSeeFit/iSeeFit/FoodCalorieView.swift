//
//  FoodCalorieView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import SwiftUI

struct FoodCalorieView: View {
    @StateObject private var manager = FoodRecognitionManager()
    @State private var selectedImage: UIImage?
    @State private var showPicker = false
    @State private var useCamera = false

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
        .navigationTitle("Food Calories")
    }
}

struct FoodCalorieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { FoodCalorieView() }
    }
}



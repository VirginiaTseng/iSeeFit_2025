//
//  FoodAnalysisManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-01-25.
//

import Foundation
import UIKit
import SwiftUI

class FoodAnalysisManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var analysisResult: FoodAnalysisResponse?
    @Published var errorMessage: String?
    @Published var config: FoodAnalysisConfigResponse?
    
    // MARK: - Analysis Settings
    @Published var useAIPortions = true
    @Published var manualOverride = ""
    @Published var portionSlider: Double = 250.0
    @Published var useOpenAI = true  // 新增：是否使用 OpenAI 直连
    
    private let apiService = APIService.shared
    
    init() {
        Task {
            await loadConfig()
        }
    }
    
    // MARK: - Public Methods
    func analyze(image: UIImage) async {
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
            analysisResult = nil
        }
        
        do {
            // let result = try await apiService.analyzeFood(
            //     image: image,
            //     useAIPortions: useAIPortions,
            //     manualOverride: manualOverride,
            //     portionSlider: portionSlider
            // )

            let result: FoodAnalysisResponse
            if useOpenAI {
                result = try await OpenAIService.shared.analyzeFoodWithOpenAI(image: image)
            } else {
                result = try await apiService.analyzeFood(
                    image: image,
                    useAIPortions: useAIPortions,
                    manualOverride: manualOverride,
                    portionSlider: portionSlider
                )
            }
            await MainActor.run {
                self.analysisResult = result
                self.isAnalyzing = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isAnalyzing = false
            }
        }
    }
    
    func loadConfig() async {
        do {
            let config = try await apiService.getFoodAnalysisConfig()
            await MainActor.run {
                self.config = config
            }
        } catch {
            print("Failed to load food analysis config: \(error)")
        }
    }
    
    func clearResults() {
        analysisResult = nil
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    var detectedFoods: [FoodAnalysisItem] {
        analysisResult?.per_item ?? []
    }
    
    var totalCalories: Double {
        analysisResult?.totals.calories_kcal ?? 0.0
    }
    
    var totalProtein: Double {
        analysisResult?.totals.protein_g ?? 0.0
    }
    
    var totalCarbs: Double {
        analysisResult?.totals.carbs_g ?? 0.0
    }
    
    var totalFat: Double {
        analysisResult?.totals.fat_g ?? 0.0
    }
    
    var totalPortion: Double {
        analysisResult?.totals.portion_g ?? 0.0
    }
    
    var analysisMode: String {
        analysisResult?.mode ?? "unknown"
    }
    
    var analysisNotes: String? {
        analysisResult?.notes
    }
    
    var hasResults: Bool {
        analysisResult != nil && !detectedFoods.isEmpty
    }
    
    var isOpenAIEnabled: Bool {
        config?.openai_enabled ?? false
    }
    
    var modelName: String? {
        config?.model_name
    }
    
    var fallbackClassifier: String {
        config?.fallback_classifier ?? "unknown"
    }
}

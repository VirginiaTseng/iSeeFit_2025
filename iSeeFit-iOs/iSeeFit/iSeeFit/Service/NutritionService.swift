//
//  NutritionService.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import Foundation

struct NutritionInfo {
    let caloriesPerServing: Double
    let servingText: String
    let normalizedName: String?
}

final class NutritionService {
    static let shared = NutritionService()

    private let session: URLSession = .shared

    // Prefer Edamam Nutrition Data API (simple) if keys exist
    private var edamamAppId: String? {
        Bundle.main.object(forInfoDictionaryKey: "EDAMAM_APP_ID") as? String
    }
    private var edamamAppKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "EDAMAM_APP_KEY") as? String
    }

    func fetch(for query: String, completion: @escaping (NutritionInfo?) -> Void) {
        // If Edamam keys available, call it; otherwise no-op
        guard let appId = edamamAppId, let appKey = edamamAppKey, !appId.isEmpty, !appKey.isEmpty else {
            completion(nil)
            return
        }

        // Use Nutrition Data API: https://api.edamam.com/api/nutrition-data
        // Construct an ingredient text like "1 serving <food>"
        let ingr = "1 serving \(query)"
        let encodedIngr = ingr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ingr
        let urlString = "https://api.edamam.com/api/nutrition-data?app_id=\(appId)&app_key=\(appKey)&ingr=\(encodedIngr)"
        guard let url = URL(string: urlString) else { completion(nil); return }

        session.dataTask(with: url) { data, _, error in
            guard error == nil, let data = data else { completion(nil); return }
            // Response example contains total calories under key "calories"
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let calories = json["calories"] as? Double {
                completion(NutritionInfo(caloriesPerServing: calories, servingText: "1 serving", normalizedName: nil))
            } else {
                completion(nil)
            }
        }.resume()
    }

    // 混合模式：先用Qwen做归一化/份量推断，再查Edamam；若无Key，则仅返回Qwen的粗估
    func fetchHybrid(foodCandidates: [String], context: String?, completion: @escaping (NutritionInfo?) -> Void) {
        QwenProvider.shared.normalizeAndEstimate(foodCandidates: foodCandidates, context: context) { qwen in
#if DEBUG
            print("[Nutrition] Qwen returned: \(qwen?.normalizedName ?? "nil")")
#endif
            guard let qwen = qwen else {
                // 没有Qwen结果，则尝试直接走Edamam（用第一个候选）
                if let first = foodCandidates.first {
#if DEBUG
                    print("[Nutrition] Fallback → Edamam with: \(first)")
#endif
                    self.fetch(for: first, completion: completion)
                } else {
                    completion(nil)
                }
                return
            }

            // 过滤：仅当完全等于泛化标签或置信度过低时忽略
            let generic: Set<String> = ["food", "dish", "meal", "cuisine"]
            if generic.contains(qwen.normalizedName.lowercased()) || (qwen.confidence ?? 0.0) < 0.4 {
#if DEBUG
                print("[Nutrition] Ignore generic/low-confidence: \(qwen.normalizedName) conf=\(qwen.confidence ?? -1)")
#endif
                completion(nil)
                return
            }

            // 如果Edamam Key存在，优先权威来源
            if let appId = self.edamamAppId, let appKey = self.edamamAppKey, !appId.isEmpty, !appKey.isEmpty {
                let query = qwen.normalizedName.isEmpty ? (foodCandidates.first ?? "") : qwen.normalizedName
#if DEBUG
                print("[Nutrition] Edamam with normalized: \(query)")
#endif
                self.fetch(for: query) { info in
                    if let info = info {
                        completion(NutritionInfo(caloriesPerServing: info.caloriesPerServing, servingText: info.servingText, normalizedName: qwen.normalizedName))
                    } else if let cal = qwen.caloriesEstimate {
#if DEBUG
                        print("[Nutrition] Edamam failed, use Qwen cal: \(cal)")
#endif
                        completion(NutritionInfo(caloriesPerServing: cal, servingText: qwen.portionText ?? "1 serving", normalizedName: qwen.normalizedName))
                    } else {
                        completion(nil)
                    }
                }
            } else {
                // 无Edamam Key，仅返回Qwen
                if let cal = qwen.caloriesEstimate {
#if DEBUG
                    print("[Nutrition] No Edamam key, use Qwen-only cal: \(cal)")
#endif
                    completion(NutritionInfo(caloriesPerServing: cal, servingText: qwen.portionText ?? "1 serving", normalizedName: qwen.normalizedName))
                } else {
                    completion(nil)
                }
            }
        }
    }
}



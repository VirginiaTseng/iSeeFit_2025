//
//  QwenProvider.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import Foundation

struct QwenNutritionResult {
    let normalizedName: String
    let portionText: String?
    let caloriesEstimate: Double?
    let confidence: Double?
}

final class QwenProvider {
    static let shared = QwenProvider()

    private var apiURL: String? { Bundle.main.object(forInfoDictionaryKey: "QWEN_API_URL") as? String }
    private var apiKey: String? { Bundle.main.object(forInfoDictionaryKey: "QWEN_API_KEY") as? String }
    private var model: String { (Bundle.main.object(forInfoDictionaryKey: "QWEN_MODEL") as? String) ?? "qwen-plus" }

    private let session: URLSession = .shared

    // 调用大模型做“菜名标准化 + 份量提取 + 粗卡路里估算（可选）”
    func normalizeAndEstimate(foodCandidates: [String], context: String?, completion: @escaping (QwenNutritionResult?) -> Void) {
        guard let apiURL, var url = URL(string: apiURL), let apiKey else {
#if DEBUG
            print("[Qwen] Skipped: API URL/KEY not configured")
#endif
            completion(nil)
            return
        }

        // 兼容 DashScope 兼容模式：如果只到 /v1 结尾，自动拼接 /chat/completions
        if url.path.hasSuffix("/v1") || url.absoluteString.hasSuffix("/v1") {
            if let fixed = URL(string: url.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions") {
                url = fixed
            }
        }

        let systemPrompt = "You are a nutrition expert. Normalize food names to a common English term and infer a typical serving text. Return JSON only."
        let userPrompt = "candidates: \(foodCandidates)\ncontext: \(context ?? "")\nReturn JSON with keys: normalized_name, portion_text, calories_estimate, confidence."

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "response_format": ["type": "json_object"]
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

#if DEBUG
        print("[Qwen] Request → model=\(model) url=\(apiURL)")
        print("[Qwen] Candidates=\(foodCandidates)")
        if let ctx = context { print("[Qwen] Context=\(ctx)") }
        if let hb = req.httpBody, let bodyStr = String(data: hb, encoding: .utf8) {
            print("[Qwen] Request body:\n\(bodyStr)")
        }
#endif
        let task = session.dataTask(with: req) { data, resp, error in
            if let error = error {
#if DEBUG
                print("[Qwen] Network error: \(error.localizedDescription)")
#endif
                completion(nil)
                return
            }
            guard let data = data else { completion(nil); return }

            if let http = resp as? HTTPURLResponse {
#if DEBUG
                print("[Qwen] HTTP status: \(http.statusCode)")
#endif
            }
            // 打印完整原始响应内容
#if DEBUG
            if let text = String(data: data, encoding: .utf8) {
                print("[Qwen] Raw response (full):\n\(text)")
            }
#endif
            // 兼容 OpenAI 风格：choices[0].message.content 为字符串(JSON)
            if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = root["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any] {

                var contentString: String?
                if let s = message["content"] as? String {
                    contentString = s
                } else if let dict = message["content"] as? [String: Any], let s = dict["content"] as? String {
                    contentString = s
                }

                if var content = contentString {
                    // 去除可能的 ```json ... ``` 包裹
                    content = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    if content.hasPrefix("```") {
                        content = content.replacingOccurrences(of: "```json", with: "")
                        content = content.replacingOccurrences(of: "```", with: "")
                        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    }

                    if let objData = content.data(using: .utf8),
                       let obj = try? JSONSerialization.jsonObject(with: objData) as? [String: Any] {
                        let normalized = (obj["normalized_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        let portion = (obj["portion_text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cal = obj["calories_estimate"] as? Double
                        let conf = obj["confidence"] as? Double
                        let result = QwenNutritionResult(normalizedName: normalized, portionText: portion, caloriesEstimate: cal, confidence: conf)
                        #if DEBUG
                        print("[Qwen] Success → normalized=\(normalized), portion=\(portion ?? "-"), cal=\(cal?.description ?? "-") conf=\(conf?.description ?? "-")")
                        #endif
                        completion(result)
                        return
                    }
                }
            }

            #if DEBUG
            if let err = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any], let e = err["error"] as? [String: Any] {
                print("[Qwen] API error: \(e)")
            } else if let text = String(data: data, encoding: .utf8) {
                print("[Qwen] Parse failed. Raw=\(text.prefix(512))...")
            } else { print("[Qwen] Parse failed. No UTF8 content") }
            #endif
            completion(nil)
        }
        task.resume()
    }
}



//
//  OCRManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-20.
//

import Vision
import UIKit
import NaturalLanguage


class OCRManager: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var translatedText: String = ""
    @Published var signLanguageGIFURL: URL?

    func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                DispatchQueue.main.async {
                    self.recognizedText = "Failed to recognize text."
                }
                return
            }

            let detectedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

            DispatchQueue.main.async {
                self.recognizedText = detectedText
                self.translatedText = self.localTranslate(detectedText)
                self.translateText(detectedText, to: "zh") // 翻译为中文
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.recognizedText = "Error processing image."
                }
            }
        }
    }
    
    /// **使用 Giphy API 获取手语 GIF**
        func fetchSignLanguageGIF(for text: String) {
            let apiKey = "YOUR_GIPHY_API_KEY"
            let query = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://api.giphy.com/v1/gifs/search?api_key=\(apiKey)&q=sign+\(query)&limit=1"

            guard let url = URL(string: urlString) else { return }

            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataArray = json["data"] as? [[String: Any]],
                   let firstResult = dataArray.first,
                   let images = firstResult["images"] as? [String: Any],
                   let original = images["original"] as? [String: Any],
                   let gifURLString = original["url"] as? String,
                   let gifURL = URL(string: gifURLString) {
                    
                    DispatchQueue.main.async {
                        self.signLanguageGIFURL = gifURL
                    }
                }
            }.resume()
        }
    
    // 翻译文本 (使用 Google Translate API)
        func translateText(_ text: String, to targetLang: String) {
            guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            
            let apiKey = "YOUR_GOOGLE_CLOUD_TRANSLATE_API_KEY"  // 👈 这里填入 Google 翻译 API Key
            let urlStr = "https://translation.googleapis.com/language/translate/v2?key=\(apiKey)&q=\(encodedText)&target=\(targetLang)"
            guard let url = URL(string: urlStr) else { return }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else { return }

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let translations = json?["data"] as? [String: Any],
                       let translatedArray = translations["translations"] as? [[String: Any]],
                       let translatedText = translatedArray.first?["translatedText"] as? String {
                        DispatchQueue.main.async {
                            self.translatedText = translatedText
                        }
                    }
                } catch {
                    print("Translation failed: \(error)")
                }
            }
            task.resume()
        }
    
//    func localTranslate(_ text: String) -> String {
//        let tagger = NLTagger(tagSchemes: [.language])
//        tagger.string = text
//        let lang = tagger.dominantLanguage ?? "en"
//        return lang == "en" ? "本地翻译示例: \(text)" : text
//    }
    func localTranslate(_ text: String) -> String {
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = text
        
        let detectedLang = tagger.dominantLanguage?.rawValue ?? "und"  // "und" 代表无法识别的语言
        
        if detectedLang == "en" {
            return "（本地翻译示例）\(text)"
        } else {
            return text
        }
    }
    
    /// 本地翻译 (快速返回)
//        func localTranslate(_ text: String) -> String {
//            let tagger = NLTagger(tagSchemes: [.language])
//            tagger.string = text
//            let lang = tagger.dominantLanguage ?? "en"
//            
//            if lang == "en" {
//                return "（本地翻译示例）\(text)"
//            } else {
//                return text
//            }
//        }

}

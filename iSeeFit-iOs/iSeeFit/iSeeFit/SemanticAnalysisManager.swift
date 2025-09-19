//
//  SemanticAnalysisManager.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import NaturalLanguage
import CoreML

class SemanticAnalysisManager {
    static let shared = SemanticAnalysisManager()
    
    private var sentimentClassifier: NLModel?
    private var topicClassifier: NLModel?
    
    init() {
        setupModels()
        
        //使用 Create ML 创建模型的示例代码
//        import CreateML
//
//        // 情感分析模型
//        let sentimentTrainingData = try MLDataTable(contentsOf: URL(fileURLWithPath: "sentiment_data.json"))
//        let sentimentClassifier = try MLTextClassifier(trainingData: sentimentTrainingData,
//                                                     textColumn: "text",
//                                                     labelColumn: "sentiment")
//
//        // 保存模型
//        try sentimentClassifier.write(to: URL(fileURLWithPath: "SentimentClassifier.mlmodel"))
        
    }
    
    private func setupModels() {
        do {
            // 注意：这里需要您先训练好模型并添加到项目中
            if let sentimentModelURL = Bundle.main.url(forResource: "SentimentClassifier", withExtension: "mlmodelc") {
                sentimentClassifier = try NLModel(contentsOf: sentimentModelURL)
            }
            
            if let topicModelURL = Bundle.main.url(forResource: "TopicClassifier", withExtension: "mlmodelc") {
                topicClassifier = try NLModel(contentsOf: topicModelURL)
            }
        } catch {
            print("模型加载错误: \(error.localizedDescription)")
        }
    }
    
    // 情感分析
    func analyzeSentiment(for text: String) -> String {
        guard let classifier = sentimentClassifier else {
            return "情感分析器未就绪"
        }
        
        let prediction = classifier.predictedLabel(for: text)
        return prediction ?? "无法确定情感"
    }
    
    // 主题分类
    func analyzeTopic(for text: String) -> String {
        guard let classifier = topicClassifier else {
            return "主题分析器未就绪"
        }
        
        let prediction = classifier.predictedLabel(for: text)
        return prediction ?? "无法确定主题"
    }
    
    // 关键词提取
    func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        
        var keywords: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let keyword = String(text[tokenRange])
                keywords.append(keyword)
            }
            return true
        }
        
        return keywords
    }
}

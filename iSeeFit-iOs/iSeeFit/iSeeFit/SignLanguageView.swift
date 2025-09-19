//
//  SignLanguageView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-20.
//

import SwiftUI
import WebKit

struct SignLanguageView: View {
    let text: String
    @State private var gifURL: URL?

    var body: some View {
        VStack {
            if let url = gifURL {
                WebView(url: url) // 显示 GIF
                    .frame(width: 300, height: 200)
            } else {
                Text("Loading sign language GIF...")
            }
        }
        .onAppear {
            fetchSignLanguageGIF(for: text)
        }
    }

    /// **使用 Giphy API 获取手语 GIF**
    func fetchSignLanguageGIF(for text: String) {
        let apiKey = "0G7yLT1D2Dvv2b8wUxHj2cyqqRU5LOem"  // 你的 Giphy API Key
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
                    self.gifURL = gifURL
                }
            }
        }.resume()
    }
}

/// **WebView 用于显示 GIF**
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

//
//  OCRView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-20.
//

import SwiftUI
import Vision
import SwiftUI
import PhotosUI

struct OCRView: View {
    @StateObject private var ocrManager = OCRManager()
        @State private var selectedImage: UIImage?
        @State private var isShowingImagePicker = false

        var body: some View {
            VStack {
                // 如果用户选择了图片，则显示图片
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .padding()
                }

                // 按钮：选择图片
                Button("Select Image") {
                    isShowingImagePicker = true
                }
                .padding()
                .buttonStyle(.borderedProminent)

                // 显示 OCR 识别出的文本
                VStack(alignment: .leading) {
                    Text("Recognized Text:") // 识别的文本
                        .font(.headline)
                    ScrollView {
                        Text(ocrManager.recognizedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 10)
                    
                    Text("Sign Language GIF:")
                        .font(.headline)

                    if let gifURL = ocrManager.signLanguageGIFURL {
                        WebView(url: gifURL)
                            .frame(width: 300, height: 200)
                    } else {
                        Text("No sign language found.")
                            .italic()
                    }

//                    Text("Translated Text (Chinese):") // 翻译文本（中文）
//                        .font(.headline)
//                    ScrollView {
//                        Text(ocrManager.translatedText)
//                            .padding()
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .background(Color(UIColor.systemGray5))
//                            .cornerRadius(8)
//                    }
//                }
//                .padding()

            }
            // 弹出图片选择器
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage, completion: { image in
                    if let image = image {
                        ocrManager.recognizeText(from: image) // 处理 OCR 识别
                    }
                })
            }
        }
    }
}

struct OCRView_Previews: PreviewProvider {
    static var previews: some View {
        OCRView()
    }
}

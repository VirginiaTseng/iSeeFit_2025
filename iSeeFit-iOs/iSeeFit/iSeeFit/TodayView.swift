//
//  TodayView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-09-19.
//

import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct TodayEntry: Identifiable {
    enum Kind { case meal, workout }
    let id = UUID()
    let time: String
    let title: String
    let calories: Int
    let kind: Kind
    let image: Image?
    let note: String?
}

struct TodayView: View {
    // 使用真实数据源
    @StateObject private var foodLocalStore = FoodLocalStore.shared
    @State private var entries: [TodayEntry] = []
    @State private var selectedEntry: TodayEntry? = nil
    @State private var showDetailView = false
    
    // 默认演示数据（当没有真实数据时显示）
    private let defaultEntries: [TodayEntry] = [
        TodayEntry(time: "08:12", title: "Breakfast", calories: 320, kind: .meal, image: nil, note: "Yogurt & fruits"),
        TodayEntry(time: "12:48", title: "Lunch", calories: 640, kind: .meal, image: nil, note: "Chicken salad"),
        TodayEntry(time: "18:30", title: "Workout", calories: 420, kind: .workout, image: nil, note: "Treadmill 40min"),
        TodayEntry(time: "20:05", title: "Dinner", calories: 510, kind: .meal, image: nil, note: "Shrimp & veggies")
    ]

    private var intake: Int { entries.filter { $0.kind == .meal }.map { $0.calories }.reduce(0, +) }
    private var burn: Int { entries.filter { $0.kind == .workout }.map { $0.calories }.reduce(0, +) }
    
    // 判断餐次类型
    private func getMealType(for date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 5..<11:
            return "Breakfast"
        case 11..<15:
            return "Lunch"
        case 15..<18:
            return "Snack"
        case 18..<22:
            return "Dinner"
        default:
            return "Snack"
        }
    }
    
    // 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 加载图片的辅助函数
    private func loadImageFromPath(_ path: String) -> Image? {
        print("DEBUG: TodayView - Attempting to load image from: \(path)")
        
        // 检查路径是否已经是绝对路径
        let imageURL: URL
        if path.hasPrefix("/") {
            // 已经是绝对路径
            imageURL = URL(fileURLWithPath: path)
        } else {
            // 相对路径，需要拼接 Documents 目录
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            imageURL = documentsPath.appendingPathComponent(path)
        }
        
        print("DEBUG: TodayView - Final image URL: \(imageURL.path)")
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            print("ERROR: TodayView - Image file does not exist at: \(imageURL.path)")
            
            // 尝试列出 Images 目录的内容来调试
            let imagesDir = imageURL.deletingLastPathComponent()
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: imagesDir.path)
                print("DEBUG: TodayView - Images directory contents: \(contents)")
            } catch {
                print("ERROR: TodayView - Failed to list Images directory: \(error)")
                
                // 尝试创建 Images 目录
                print("DEBUG: TodayView - Attempting to create Images directory")
                do {
                    try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
                    print("DEBUG: TodayView - Successfully created Images directory")
                } catch {
                    print("ERROR: TodayView - Failed to create Images directory: \(error)")
                }
            }
            return nil
        }
        
        // 检查文件大小
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: imageURL.path)
            if let fileSize = attributes[.size] as? NSNumber {
                print("DEBUG: TodayView - Image file size: \(fileSize.intValue) bytes")
            }
        } catch {
            print("WARNING: TodayView - Could not get file attributes: \(error)")
        }
        
        // 尝试加载图片
        #if canImport(UIKit)
        guard let uiImage = UIImage(contentsOfFile: imageURL.path) else {
            print("ERROR: TodayView - Failed to create UIImage from file: \(imageURL.path)")
            return nil
        }
        
        print("DEBUG: TodayView - Successfully loaded image from: \(imageURL.path)")
        return Image(uiImage: uiImage)
        #else
        // 在 macOS 上使用 NSImage
        guard let nsImage = NSImage(contentsOf: imageURL) else {
            print("ERROR: TodayView - Failed to create NSImage from file: \(imageURL.path)")
            return nil
        }
        
        print("DEBUG: TodayView - Successfully loaded image from: \(imageURL.path)")
        return Image(nsImage: nsImage)
        #endif
    }
    
    // 加载今日数据
    private func loadTodayData() {
        let todayRecords = foodLocalStore.getTodayRecords()
        print("DEBUG: TodayView - Found \(todayRecords.count) records for today")
        
        if todayRecords.isEmpty {
            // 没有数据时使用默认演示数据
            entries = defaultEntries
            print("DEBUG: TodayView - Using default entries")
        } else {
            // 有数据时转换为 TodayEntry 格式
            entries = todayRecords.map { record in
                // 尝试加载图片
                var foodImage: Image? = nil
                if let imagePath = record.imagePath {
                    print("DEBUG: TodayView - Loading image from path: \(imagePath)")
                    if let image = loadImageFromPath(imagePath) {
                        foodImage = image
                        print("DEBUG: TodayView - Successfully loaded image")
                    } else {
                        print("DEBUG: TodayView - Failed to load image from path: \(imagePath)")
                    }
                } else {
                    print("DEBUG: TodayView - No image path for record: \(record.foodName)")
                }
                
                return TodayEntry(
                    time: formatTime(record.date),
                    title: getMealType(for: record.date),
                    calories: Int(record.calories),
                    kind: .meal,
                    image: foodImage,
                    note: record.notes
                )
            }.sorted { $0.time < $1.time }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    
                    timeline

                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            // .navigationBarTitleDisplayMode(.inline) // 在 macOS 上不可用
//            .toolbar { ToolbarItem(placement: .principal) { Text("Today's Memory").font(.headline) } }
            .background(LinearGradient(colors: [Color.black.opacity(0.04), Color.clear], startPoint: .top, endPoint: .bottom))
        .onAppear {
            loadTodayData()
        }
        .onChange(of: foodLocalStore.records) {
            loadTodayData()
        }
        }
    }

    private var header: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Color.yellow.opacity(0.35), Color.orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 120)
            VStack(alignment: .leading, spacing: 8) {
                //Text("Today's Memory").font(.title3).bold()
                Text("Track your meals and workouts today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                summary
            }
            .padding(16)
        }
    }

    private var timeline: some View {
        VStack(spacing: 24) {
            ForEach(entries) { item in
                HStack(alignment: .top, spacing: 12) {
                    // 左列（餐饮）
                    Group {
                        if item.kind == .meal {
                            entryCard(item)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            Spacer(minLength: 0)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // 中线与时间
                    VStack(spacing: 6) {
                        Text(item.time)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Circle().fill(item.kind == .meal ? Color.orange : Color.green)
                            .frame(width: 10, height: 10)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.25))
                            .frame(width: 2, height: 90)
                    }

                    // 右列（健身）
                    Group {
                        if item.kind == .workout {
                            entryCard(item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer(minLength: 0)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func entryCard(_ item: TodayEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title).font(.headline)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: item.kind == .meal ? "flame.fill" : "bolt.heart.fill")
                        .foregroundColor(item.kind == .meal ? .orange : .green)
                    Text("\(item.calories) kcal").font(.subheadline).bold()
                }
            }
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 110)
                .overlay(
                    ZStack {
                        if let img = item.image { 
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        }
                        if let note = item.note {
                            VStack {
                                Spacer()
                                Text(note)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.6))
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                )
        }
        .onTapGesture {
            print("DEBUG: TodayView - Card tapped for: \(item.title)")
            selectedEntry = item
            showDetailView = true
        }
        .sheet(isPresented: $showDetailView) {
            if let entry = selectedEntry {
                FoodDetailView(entry: entry)
            }
        }
    }

    private var summary: some View {
        VStack(spacing: 2) {
            HStack {
                Label("Intake", systemImage: "fork.knife").foregroundColor(.orange)
                Spacer()
                Text("\(intake) kcal").bold()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))

            HStack {
                Label("Burned", systemImage: "figure.run").foregroundColor(.green)
                Spacer()
                Text("\(burn) kcal").bold()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.05)))

            HStack {
                Label("Net", systemImage: "scalemass").foregroundColor(.blue)
                Spacer()
                Text("\(intake - burn) kcal").bold()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
        }
    }
}

// MARK: - Food Detail View
struct FoodDetailView: View {
    let entry: TodayEntry
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 食物图片区域
                    if let image = entry.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 300)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.7))
                            )
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // 食物信息卡片
                    VStack(alignment: .leading, spacing: 16) {
                        // 标题和卡路里
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text(entry.time)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(entry.calories)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(entry.kind == .meal ? .orange : .green)
                                
                                Text("kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // 营养信息（模拟数据）
                        VStack(spacing: 12) {
                            Text("营养分析")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 20) {
                                NutritionItem(title: "蛋白质", value: "25g", color: .blue)
                                NutritionItem(title: "碳水", value: "45g", color: .green)
                                NutritionItem(title: "脂肪", value: "15g", color: .purple)
                            }
                        }
                        
                        // 备注信息
                        if let note = entry.note {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("备注")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(note)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.primary.opacity(0.05))
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                }
                .padding()
            }
            .navigationTitle("食物详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Nutrition Item
struct NutritionItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct TodayView_Previews: PreviewProvider {
    static var previews: some View { TodayView() }
}



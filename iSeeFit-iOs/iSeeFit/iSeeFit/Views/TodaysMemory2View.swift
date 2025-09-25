//
//  TodaysMemory2View.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//


import SwiftUI

struct TodaysMemoryView2: View {
    @State private var scrollOffset: CGFloat = 0
    @StateObject private var animationManager = ScrollAnimationManager()
    @State private var useObservablePattern = true
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 固定在上方的头部卡片 - 使用 TodaysMemoryBkCard
                //TodaysMemoryBkCard(externalScrollOffset: scrollOffset)
                //AnimatedHeaderView()
                // Method 1: Using @Binding
                if !useObservablePattern {
                    AnimatedHeaderView(scrollOffset: $scrollOffset)
                } else {
                    // Method 2: Using ObservableObject
                    ObservableHeaderView(animationManager: animationManager)
                }
                
                // 可滚动的内容区域
                ScrollView {
                    contentView()
                        .background(GeometryReader { geo in
                            Color.clear.onAppear {
                                //scrollOffset = geo.frame(in: .global).minY
                                if useObservablePattern {
                                    animationManager.scrollOffset = geo.frame(in: .global).minY
                                } else {
                                    scrollOffset = geo.frame(in: .global).minY
                                }
                            }
                            .onChange(of: geo.frame(in: .global).minY) { newValue in
                                //scrollOffset = geo.frame(in: .global).minY
                                // 动画现在由 TodaysMemoryBkCard 内部处理
                                if useObservablePattern {
                                    animationManager.scrollOffset = newValue
                                } else {
                                    scrollOffset = newValue
                                }
                            }
                        })
                }
                
                // Toggle button for demo
                 Button("Toggle Pattern: \(useObservablePattern ? "Observable" : "Binding")") {
                     useObservablePattern.toggle()
                 }
                 .padding()
            }
        }
        .ignoresSafeArea()
        // 动画现在由 TodaysMemoryBkCard 内部处理
    }
    
    private func contentView() -> some View {
        VStack(spacing: 20) {
            // Timeline dots
            timelineView()
            
            // Memory cards
            memoryCardsView()
        }
        .padding(.top, 20)
        .background(Color.white)
    }
    
    private func timelineView() -> some View {
        HStack {
            //ForEach(["01:23", "01:23", "01:17", "01:09", "01:09", "01:09", "01:09"], id: \.self) { time in
            ForEach(Array(["01:23", "01:23", "01:17", "01:09", "01:09", "01:09", "01:09"].enumerated()), id: \.offset) { index, time in
                VStack(spacing: 5) {
                    Text(time)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 30, height: 30)
                        
                        Text("1")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                if time != "01:09" {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func memoryCardsView() -> some View {
        VStack(spacing: 20) {
            // First memory card
            memoryCard(time: "01:23", title: "Yummy Food", calories: "300kcal", imageName: "fork.knife", isHighlighted: true)
            
            // Second memory card
            memoryCard(time: "01:23", title: "Yummy Food", calories: "", imageName: "fork.knife", isHighlighted: false)
        }
        .padding(.horizontal, 20)
    }
    
    private func memoryCard(time: String, title: String, calories: String, imageName: String, isHighlighted: Bool) -> some View {
        HStack {
            // Left side
            VStack(alignment: .leading, spacing: 5) {
                Text("1")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.orange)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                
                if !calories.isEmpty {
                    Text("calorie: \(calories)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                // Food image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 80)
                    .overlay(
                        Image(systemName: imageName)
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    )
            }
            
            Spacer()
            
            // Right side
            VStack {
                // Time indicator
                Text(time)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isHighlighted ? Color.green : Color.gray.opacity(0.3))
                    .foregroundColor(isHighlighted ? .white : .gray)
                    .cornerRadius(15)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if isHighlighted {
                        Text("Next record will analyze")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("previous data,Completed")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        HStack {
                            Text("3")
                                .font(.system(size: 16, weight: .bold))
                            Text("times,No records for this")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        Text("task last week")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text("Since last time 2days,")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        HStack {
                            Text("1")
                                .font(.system(size: 16, weight: .bold))
                            Text("hrs,Completed")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text("3")
                                .font(.system(size: 16, weight: .bold))
                        }
                        Text("times,No records for this")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("task last week")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 5)
    }
    
    // 所有动画和头部视图功能现在由 TodaysMemoryBkCard 处理
    
}



struct TodaysMemoryView2_Previews: PreviewProvider {
    static var previews: some View {
        TodaysMemoryView2()
    }
}

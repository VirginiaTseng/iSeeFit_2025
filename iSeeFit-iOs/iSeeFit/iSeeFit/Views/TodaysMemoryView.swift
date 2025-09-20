//
//  TodaysMemoryView.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//

import SwiftUI

struct TodaysMemoryView: View {
    @State private var scrollOffset: CGFloat = 0
    // 注意：其他动画状态变量现在由 TodaysMemoryBkCard 内部管理
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header with animated background and chicken using TodaysMemoryBkCard
                    TodaysMemoryBkCard(externalScrollOffset: scrollOffset)
                    
                    // Content area
                    contentView()
                }
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        scrollOffset = geo.frame(in: .global).minY
                    }
                    .onChange(of: geo.frame(in: .global).minY) {
                        scrollOffset = geo.frame(in: .global).minY
                        // 动画现在由 TodaysMemoryBkCard 内部处理
                    }
                })
            }
        }
        .ignoresSafeArea()
        // 动画现在由 TodaysMemoryBkCard 内部处理
    }
    
//    private func headerView(geometry: GeometryProxy) -> some View {
//        ZStack {
//            // Moving gradient background
//            MovingGradientBackground(scrollOffset: scrollOffset, glowPhase: glowPhase)
//                .frame(height: 300)
//            
//            VStack(spacing: 20) {
//                HStack {
////                    Text("02:43")
////                        .font(.system(size: 18, weight: .semibold))
////                        .foregroundColor(.black)
////                    Spacer()
//                    // Status bar icons
//                    HStack(spacing: 5) {
//                        Circle().fill(Color.black).frame(width: 4, height: 4)
//                        Circle().fill(Color.black).frame(width: 4, height: 4)
//                        Circle().fill(Color.black).frame(width: 4, height: 4)
//                        Image(systemName: "wifi")
//                        Image(systemName: "battery.75")
//                            .foregroundColor(.green)
//                    }
//                    .font(.system(size: 14))
//                    .foregroundColor(.black)
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 10)
//                
//                // Title
//                HStack {
//                    Text("Today's Memory")
//                        .font(.system(size: 22, weight: .semibold))
//                        .foregroundColor(.black)
//                    Spacer()
//                }
//                .padding(.horizontal, 20)
//                .overlay(
//                    // Underline
//                    Rectangle()
//                        .fill(Color.green)
//                        .frame(width: 100, height: 3)
//                        .offset(x: -90, y: 15)
//                )
//                
//                Spacer()
//                
//                // Animated Chicken and Star
//                chickenStarView()
//                
//                Spacer()
//            }
//        }
//    }
//    
//    private func chickenStarView() -> some View {
//        ZStack {
//            // Star with rope/string
//            starWithRope()
//            
//            // Chicken
//            chickenView()
//        }
//        .frame(height: 120)
//    }
//    
//    private func chickenView() -> some View {
//        HStack {
//            ZStack {
//                // Chicken body
//                Ellipse()
//                    .fill(
//                        LinearGradient(
//                            colors: [Color.yellow, Color.orange.opacity(0.8)],
//                            startPoint: .top,
//                            endPoint: .bottom
//                        )
//                    )
//                    .frame(width: 60, height: 55)
//                
//                // Chicken comb
//                HStack(spacing: 2) {
//                    ForEach(0..<3) { _ in
//                        Ellipse()
//                            .fill(Color.orange)
//                            .frame(width: 8, height: 15)
//                    }
//                }
//                .offset(y: -25)
//                
//                // Eyes that follow the star
//                HStack(spacing: 8) {
//                    eyeView()
//                    eyeView()
//                }
//                .offset(y: -8)
//                .rotationEffect(.degrees(eyeRotation))
//                
//                // Beak
//                Triangle()
//                    .fill(Color.orange)
//                    .frame(width: 8, height: 6)
//                    .offset(x: 25, y: -2)
//                
//                // Wing
//                Ellipse()
//                    .fill(Color.orange.opacity(0.7))
//                    .frame(width: 20, height: 35)
//                    .offset(x: -5, y: 5)
//                
//                // Feet
//                HStack(spacing: 15) {
//                    chickenFoot()
//                    chickenFoot()
//                }
//                .offset(y: 25)
//            }
//            
//            Spacer()
//        }
//        .padding(.leading, 40)
//    }
//    
//    private func eyeView() -> some View {
//        ZStack {
//            Circle()
//                .fill(Color.white)
//                .frame(width: 8, height: 8)
//            Circle()
//                .fill(Color.black)
//                .frame(width: 4, height: 4)
//        }
//    }
//    
//    private func chickenFoot() -> some View {
//        VStack(spacing: 0) {
//            Rectangle()
//                .fill(Color.orange)
//                .frame(width: 2, height: 8)
//            HStack(spacing: 1) {
//                ForEach(0..<3) { _ in
//                    Rectangle()
//                        .fill(Color.orange)
//                        .frame(width: 1, height: 4)
//                }
//            }
//        }
//    }
//    
//    private func starWithRope() -> some View {
//        HStack {
//            Spacer()
//            
//            VStack(spacing: 0) {
//                // Rope/String - curved path
//                Path { path in
//                    let startX: CGFloat = -120
//                    let startY: CGFloat = 0
//                    let endX: CGFloat = starOffset
//                    let endY: CGFloat = -20
//                    
//                    let controlX = (startX + endX) / 2
//                    let controlY = min(startY, endY) - abs(endX - startX) * 0.1
//                    
//                    path.move(to: CGPoint(x: startX, y: startY))
//                    path.addQuadCurve(
//                        to: CGPoint(x: endX, y: endY),
//                        control: CGPoint(x: controlX, y: controlY)
//                    )
//                }
//                .stroke(Color.brown, lineWidth: 2)
//                
//                // Star
////                StarShape()
////                    .fill(Color.yellow)
////                    .frame(width: 25, height: 25)
////                    .offset(x: starOffset, y: -20)
////                    .shadow(color: .yellow.opacity(0.6), radius: 8)
//                StarShape()
//                    .fill(Color.yellow)
//                    .frame(width: 25, height: 25)
//                    .offset(x: starOffset, y: -20)
//                    .rotationEffect(.degrees(starRotation))
//                    .shadow(color: .yellow.opacity(0.6), radius: 8)
//                    .overlay(
//                        // Glowing aura around star
//                        StarShape()
//                            .fill(Color.yellow.opacity(0.3))
//                            .frame(width: 35, height: 35)
//                            .blur(radius: 5)
//                            .scaleEffect(1.0 + sin(glowPhase) * 0.2)
//                            .offset(x: starOffset, y: -20)
//                            .rotationEffect(.degrees(starRotation))
//                    )
//            }
//            
//            Spacer()
//        }
//    }
    
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
            ForEach(["01:23", "01:23", "01:17", "01:09", "01:09", "01:09", "01:09"], id: \.self) { time in
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
    
    // 动画函数已移动到 TodaysMemoryBkCard 中
    
}



struct TodaysMemoryView_Previews: PreviewProvider {
    static var previews: some View {
        TodaysMemoryView()
    }
}

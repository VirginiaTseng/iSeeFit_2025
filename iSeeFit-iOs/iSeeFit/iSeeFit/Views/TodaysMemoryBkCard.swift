//
//  TodaysMemoryBkCard.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//


import SwiftUI

struct TodaysMemoryBkCard: View {
    // MARK: - Properties
    @State private var scrollOffset: CGFloat = 0
    @State private var starOffset: CGFloat = 0
    @State private var eyeRotation: Double = 0
    @State private var isAnimating = false
    @State private var starRotation: Double = 0
    @State private var glowPhase: Double = 0
    
    // MARK: - Public interface for external scroll offset
    var externalScrollOffset: CGFloat = 0
    
    // MARK: - Initializer
    init(externalScrollOffset: CGFloat = 0) {
        self.externalScrollOffset = externalScrollOffset
    }
    
    var body: some View {
        GeometryReader { geometry in
            headerView(geometry: geometry)
        }
        .frame(height: 300) // 设置固定高度确保正确显示
        .onAppear {
            startIdleAnimations()
        }
        .onChange(of: externalScrollOffset) {
            updateAnimations()
        }
    }
    
    // MARK: - Header View Implementation
    private func headerView(geometry: GeometryProxy) -> some View {
        ZStack {
            // Moving gradient background
            MovingGradientBackground(
                scrollOffset: externalScrollOffset != 0 ? externalScrollOffset : scrollOffset, 
                glowPhase: glowPhase
            )
                .frame(height: 300)
            
            VStack(spacing: 20) {
                HStack {
    //                    Text("02:43")
    //                        .font(.system(size: 18, weight: .semibold))
    //                        .foregroundColor(.black)
    //                    Spacer()
                    // Status bar icons
                    HStack(spacing: 5) {
                        Circle().fill(Color.black).frame(width: 4, height: 4)
                        Circle().fill(Color.black).frame(width: 4, height: 4)
                        Circle().fill(Color.black).frame(width: 4, height: 4)
                        Image(systemName: "wifi")
                        Image(systemName: "battery.75")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Title
                HStack {
                    Text("Today's Memory")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .overlay(
                    // Underline
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 100, height: 3)
                        .offset(x: -90, y: 15)
                )
                
                Spacer()
                
                // Animated Chicken and Star
                chickenStarView()
                
                Spacer()
            }
        }
    }
    
    private func chickenStarView() -> some View {
        ZStack {
            // Star with rope/string
            starWithRope()
            
            // Chicken
            chickenView()
        }
        .frame(height: 120)
    }
    
    private func chickenView() -> some View {
        HStack {
            ZStack {
                // Chicken body
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 55)
                
                // Chicken comb
                HStack(spacing: 2) {
                    ForEach(0..<3) { _ in
                        Ellipse()
                            .fill(Color.orange)
                            .frame(width: 8, height: 15)
                    }
                }
                .offset(y: -25)
                
                // Eyes that follow the star
                HStack(spacing: 8) {
                    eyeView()
                    eyeView()
                }
                .offset(y: -8)
                .rotationEffect(.degrees(eyeRotation))
                
                // Beak
                Triangle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 6)
                    .offset(x: 25, y: -2)
                
                // Wing
                Ellipse()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: 20, height: 35)
                    .offset(x: -5, y: 5)
                
                // Feet
                HStack(spacing: 15) {
                    chickenFoot()
                    chickenFoot()
                }
                .offset(y: 25)
            }
            
            Spacer()
        }
        .padding(.leading, 40)
    }
    
    private func eyeView() -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
            Circle()
                .fill(Color.black)
                .frame(width: 4, height: 4)
        }
    }
    
    private func chickenFoot() -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.orange)
                .frame(width: 2, height: 8)
            HStack(spacing: 1) {
                ForEach(0..<3) { _ in
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 1, height: 4)
                }
            }
        }
    }
    
    private func starWithRope() -> some View {
        HStack {
            Spacer()
            
            VStack(spacing: 0) {
                // Rope/String - curved path
                Path { path in
                    let startX: CGFloat = -120
                    let startY: CGFloat = 0
                    let endX: CGFloat = starOffset
                    let endY: CGFloat = -20
                    
                    let controlX = (startX + endX) / 2
                    let controlY = min(startY, endY) - abs(endX - startX) * 0.1
                    
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addQuadCurve(
                        to: CGPoint(x: endX, y: endY),
                        control: CGPoint(x: controlX, y: controlY)
                    )
                }
                .stroke(Color.brown, lineWidth: 2)
                
                // Star
//                StarShape()
//                    .fill(Color.yellow)
//                    .frame(width: 25, height: 25)
//                    .offset(x: starOffset, y: -20)
//                    .shadow(color: .yellow.opacity(0.6), radius: 8)
                StarShape()
                    .fill(Color.yellow)
                    .frame(width: 25, height: 25)
                    .offset(x: starOffset, y: -20)
                    .rotationEffect(.degrees(starRotation))
                    .shadow(color: .yellow.opacity(0.6), radius: 8)
                    .overlay(
                        // Glowing aura around star
                        StarShape()
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 35, height: 35)
                            .blur(radius: 5)
                            .scaleEffect(1.0 + sin(glowPhase) * 0.2)
                            .offset(x: starOffset, y: -20)
                            .rotationEffect(.degrees(starRotation))
                    )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Animation Functions
    private func updateAnimations() {
        // Use external scroll offset if provided, otherwise use internal
        let currentScrollOffset = externalScrollOffset != 0 ? externalScrollOffset : scrollOffset
        let scrollProgress = min(max(-currentScrollOffset / 200, 0), 1)
        
        // Star movement - throw out when scrolling down
        withAnimation(.easeOut(duration: 0.3)) {
            starOffset = scrollProgress * 80
        }
        
        // Eye rotation to follow star
        withAnimation(.easeOut(duration: 0.3)) {
            eyeRotation = scrollProgress * 15
        }
    }
    
    private func startIdleAnimations() {
        // Continuous star rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            starRotation = 360
        }
        
        // Continuous glow pulsing
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPhase = Double.pi * 2
        }
    }
}

// MARK: - Supporting Views and Shapes
struct MovingGradientBackground: View {
    let scrollOffset: CGFloat
    let glowPhase: Double
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.pink.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.green.opacity(0.2),
                    Color.yellow.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Moving gradient overlay
            RadialGradient(
                colors: [
                    Color.blue.opacity(0.4),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 200
            )
            .offset(x: scrollOffset * 0.1, y: scrollOffset * 0.05)
            
            RadialGradient(
                colors: [
                    Color.pink.opacity(0.3),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 150
            )
            .offset(x: -scrollOffset * 0.08, y: scrollOffset * 0.03)
            
            
            // Animated glowing orbs
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                [Color.yellow, Color.blue, Color.pink][index].opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .offset(
                        x: sin(glowPhase + Double(index) * 2) * 50,
                        y: cos(glowPhase + Double(index) * 1.5) * 30
                    )
                    .scaleEffect(0.8 + sin(glowPhase + Double(index)) * 0.3)
                    .opacity(0.6 + sin(glowPhase + Double(index) * 0.7) * 0.4)
            }
            
            // Additional ambient light particles
            ForEach(0..<5) { index in
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: sin(glowPhase * 1.5 + Double(index) * 1.2) * 80,
                        y: cos(glowPhase * 0.8 + Double(index) * 0.9) * 60
                    )
                    .scaleEffect(0.5 + sin(glowPhase + Double(index) * 2) * 0.5)
            }
        }
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        
        var path = Path()
        
        for i in 0..<10 {
            let angle = (Double(i) * Double.pi) / 5.0 - Double.pi / 2.0
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
struct TodaysMemoryBkCard_Previews: PreviewProvider {
    static var previews: some View {
        TodaysMemoryBkCard()
    }
}

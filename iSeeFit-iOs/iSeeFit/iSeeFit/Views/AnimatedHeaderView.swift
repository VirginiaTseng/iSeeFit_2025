//
//  AnimatedHeaderView.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//

import SwiftUI

// Method 1: Using @Binding - Simple and Direct
struct AnimatedHeaderView: View {
    @Binding var scrollOffset: CGFloat
    @State private var starOffset: CGFloat = 0
    @State private var eyeRotation: Double = 0
    @State private var starRotation: Double = 0
    @State private var glowPhase: Double = 0
    
    var body: some View {
        ZStack {
            // Moving gradient background with animated glow
            MovingGradientBackground(scrollOffset: scrollOffset, glowPhase: glowPhase)
                .frame(height: 300)
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
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
                        .font(.system(size: 24, weight: .semibold))
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
        .onAppear {
            startIdleAnimations()
        }
        .onChange(of: scrollOffset) { _ in
            updateAnimations()
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
    
    private func updateAnimations() {
        let scrollProgress = min(max(-scrollOffset / 200, 0), 1)
        
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

// Method 2: Using ObservableObject - More Scalable for Complex Apps
class ScrollAnimationManager: ObservableObject {
    @Published var scrollOffset: CGFloat = 0
    @Published var starOffset: CGFloat = 0
    @Published var eyeRotation: Double = 0
    
    func updateAnimations() {
        let scrollProgress = min(max(-scrollOffset / 200, 0), 1)
        
        withAnimation(.easeOut(duration: 0.3)) {
            starOffset = scrollProgress * 80
            eyeRotation = scrollProgress * 15
        }
    }
}

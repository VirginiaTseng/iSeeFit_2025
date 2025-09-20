//
//  ObservableHeaderView.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//
import SwiftUI


struct ObservableHeaderView: View {
    @ObservedObject var animationManager: ScrollAnimationManager
    @State private var starRotation: Double = 0
    @State private var glowPhase: Double = 0
    
    var body: some View {
        ZStack {
            MovingGradientBackground(scrollOffset: animationManager.scrollOffset, glowPhase: glowPhase)
                .frame(height: 300)
            
            // ... same UI content as AnimatedHeaderView but using animationManager.scrollOffset
            // This is just showing the concept - full implementation would be similar
            
            Text("Observable Header - Scroll: \(animationManager.scrollOffset, specifier: "%.1f")")
                .foregroundColor(.black)
        }
        .onAppear {
            startIdleAnimations()
        }
        .onChange(of: animationManager.scrollOffset) { _ in
            animationManager.updateAnimations()
        }
    }
    
    private func startIdleAnimations() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            starRotation = 360
        }
        
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            glowPhase = Double.pi * 2
        }
    }
}



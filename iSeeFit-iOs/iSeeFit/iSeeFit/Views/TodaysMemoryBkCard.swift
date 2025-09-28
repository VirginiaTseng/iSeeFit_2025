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
    @State private var avocadoAppear: Bool = false
    @State private var avocadoActive: Bool = false
    
    // MARK: - Public interface for external scroll offset
    var externalScrollOffset: CGFloat = 0
    var burnedValue: Int = 0
    
    // MARK: - Computed property for star count
    private var starCount: Int {
        max(burnedValue / 100, 1) // 每100 burned值一个星星，至少1个
    }
    
    // MARK: - Initializer
    init(externalScrollOffset: CGFloat = 0, burnedValue: Int = 0) {
        self.externalScrollOffset = externalScrollOffset
        self.burnedValue = burnedValue
    }
    
    var body: some View {
        GeometryReader { geometry in
            headerView(geometry: geometry)
        }
        .frame(height:340) // 增加高度以适应新的布局
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
            // 渐变背景 - 占满整个容器，底部添加倒角
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.green.opacity(0.3),
                            Color.orange.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(
                    // 自定义形状：只有底部倒角，增大圆角
                    RoundedCorners(radius: 40, corners: [.bottomLeft, .bottomRight])
                )
                .ignoresSafeArea(.all) // 确保背景覆盖所有区域
            
            
            VStack(spacing: 10) {
                // 增加顶部间距，避免与灵动岛冲突
                Spacer()
                    .frame(height: 60) // 增加间距，为灵动岛留出空间
                
                // 欢迎语板块
                motivationalHeader
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // 显示星星动画
                chickenStarView()
                
                Spacer()
            }
        }
    }
    
    private func chickenStarView() -> some View {
        ZStack {
            // 只显示星星
            starWithRope()
        }
        .frame(height: 120)
    }
    
    private func avocadoView() -> some View {
        HStack {
            ZStack {
                // 牛油果主体
                AvocadoBody()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 70)
                    .scaleEffect(avocadoAppear ? 1.0 : 0.8)
                    .offset(x: avocadoAppear ? 0 : -20, y: avocadoAppear ? 0 : 10)
                
                // 牛油果核
                AvocadoSeed()
                    .fill(Color.brown.opacity(0.8))
                    .frame(width: 20, height: 30)
                    .offset(y: 5)
                    .scaleEffect(avocadoAppear ? 1.0 : 0.6)
                    .offset(x: avocadoAppear ? 0 : 15, y: avocadoAppear ? 0 : -5)
                
                // 叶子
                AvocadoLeaf()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 25, height: 15)
                    .offset(y: -25)
                    .rotationEffect(.degrees(avocadoAppear ? 0 : -15))
                    .offset(x: avocadoAppear ? 0 : -10, y: avocadoAppear ? 0 : -5)
            }
            .opacity(avocadoActive ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    avocadoAppear = true
                    avocadoActive = true
                }
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
        ZStack {
            // 生成多个星星
            ForEach(0..<starCount, id: \.self) { index in
                let offsetMultiplier = CGFloat(index - starCount / 2) * 40 // 星星间距
                let delayOffset = Double(index) * 0.5 // 动画延迟
                
                StarShape()
                    .fill(Color.yellow)
                    .frame(width: 20 + CGFloat(index % 3) * 5, height: 20 + CGFloat(index % 3) * 5) // 不同大小
                    .offset(
                        x: starOffset + offsetMultiplier + sin(glowPhase + delayOffset) * 15,
                        y: -20 + cos(glowPhase + delayOffset) * 10
                    )
                    .rotationEffect(.degrees(starRotation + Double(index) * 45))
                    .shadow(color: .yellow.opacity(0.6), radius: 6)
                    .overlay(
                        // 发光光环
                        StarShape()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 30 + CGFloat(index % 3) * 5, height: 30 + CGFloat(index % 3) * 5)
                            .blur(radius: 4)
                            .scaleEffect(1.0 + sin(glowPhase + delayOffset) * 0.15)
                            .offset(
                                x: starOffset + offsetMultiplier + sin(glowPhase + delayOffset) * 15,
                                y: -20 + cos(glowPhase + delayOffset) * 10
                            )
                            .rotationEffect(.degrees(starRotation + Double(index) * 45))
                    )
            }
        }
        .frame(height: 80) // 给星星足够的显示空间
    }
    
    // MARK: - Motivational Header
    private var motivationalHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🍽️ Track for Today")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 1, y: 1)
                    
                    Text("Every bite and every step counts!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.4), radius: 1.5, x: 0.5, y: 0.5)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
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
                    Color.blue.opacity(0.1),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 400
            )
            .offset(x: scrollOffset * 0.1, y: scrollOffset * 0.05)
            
            RadialGradient(
                colors: [
                    Color.pink.opacity(0.1),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 250
            )
            .offset(x: -scrollOffset * 0.08, y: scrollOffset * 0.03)
            
            
            // Animated glowing orbs
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                [Color.yellow, Color.blue, Color.pink][index].opacity(0.15),
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

// MARK: - Custom Rounded Corners Shape
struct RoundedCorners: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


// MARK: - Preview
struct TodaysMemoryBkCard_Previews: PreviewProvider {
    static var previews: some View {
        TodaysMemoryBkCard()
    }
}

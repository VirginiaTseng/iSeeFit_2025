//
//  AnimatedWave.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import SwiftUI

struct AnimatedWave: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat // New variable for animation

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midHeight = rect.height / 2
        let width = rect.width

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sineY = sin((relativeX * .pi * frequency) + phase) * amplitude
            let y = midHeight + sineY
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

struct AnimatedWaveView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        AnimatedWave(amplitude: 50, frequency: 2, phase: phase)
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: 300, height: 100)
            .onAppear {
                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }
    }
}
#Preview {
    //You can animate the wave motion by varying the phase over time:
    AnimatedWave(amplitude: 40, frequency: 2.5, phase: 10)
}

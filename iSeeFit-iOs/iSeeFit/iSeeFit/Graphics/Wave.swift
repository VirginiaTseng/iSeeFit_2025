//
//  Wave.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//


import SwiftUI

struct Wave: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.pink, location: 0),
                .init(color: Color.red, location: 1),
                .init(color: Color.purple, location: 1)
            ]),
            startPoint: UnitPoint(x: 0.5317, y: 0.6424),
            endPoint: UnitPoint(x: 0.61435, y: 0.37086)
        )
        .mask(wave(amplitude: 40, frequency: 2.5).frame(width: 1948, height: 913)) //wave1()
        .frame(width: 1948, height: 913)
        .offset(x: 0, y: 350)
    }
}

struct Wave_Previews: PreviewProvider {
    static var previews: some View {
        Wave()
    }
}

struct wave: Shape {
    var amplitude: CGFloat = 50 // Height of the wave
    var frequency: CGFloat = 3  // Number of waves

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midHeight = rect.height / 2
        let width = rect.size.width

        path.move(to: CGPoint(x: 0, y: midHeight)) // Start at the left edge

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width // Normalize x to [0,1]
            let sineY = sin(relativeX * .pi * frequency) * amplitude
            let y = midHeight + sineY
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Close the path at the bottom
        path.addLine(to: CGPoint(x: width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}


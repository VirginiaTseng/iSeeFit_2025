//
//  MyCustomShape.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import SwiftUI

struct MyCustomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        path.move(to: CGPoint(x: 0.99903 * width, y: 0.5354 * height))

        path.addCurve(to: CGPoint(x: 0.5255 * width, y: 0.99874 * height),
                      control1: CGPoint(x: 0.99903 * width, y: 0.77609 * height),
                      control2: CGPoint(x: 0.88706 * width, y: 0.96836 * height))

        path.addCurve(to: CGPoint(x: 0.00458 * width, y: 0.56294 * height),
                      control1: CGPoint(x: 0.26658 * width, y: 0.99874 * height),
                      control2: CGPoint(x: 0.00458 * width, y: 0.87341 * height))

        path.addCurve(to: CGPoint(x: 0.5578 * width, y: 0.0037 * height),
                      control1: CGPoint(x: 0.00458 * width, y: 0.26046 * height),
                      control2: CGPoint(x: 0.29888 * width, y: 0.0037 * height))

        path.addCurve(to: CGPoint(x: 0.99903 * width, y: 0.5354 * height),
                      control1: CGPoint(x: 0.81672 * width, y: 0.0037 * height),
                      control2: CGPoint(x: 0.99903 * width, y: 0.29472 * height))

        path.closeSubpath()

        return path
    }
}
#Preview{MyCustomShape()}

//
//  BackG3.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import SwiftUI

struct BackG3: Shape { //Figma -> Svg ->
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        
        path.move(to: CGPoint(x: 0.83854 * width, y: 0.26662 * height))

                path.addCurve(to: CGPoint(x: 0.69959 * width, y: 0.18294 * height),
                              control1: CGPoint(x: 0.78915 * width, y: 0.30578 * height),
                              control2: CGPoint(x: 0.79248 * width, y: 0.20293 * height))

                path.addCurve(to: CGPoint(x: 0.50921 * width, y: 0.16788 * height),
                              control1: CGPoint(x: 0.6067 * width, y: 0.16296 * height),
                              control2: CGPoint(x: 0.57088 * width, y: 0.23867 * height))

                path.addCurve(to: CGPoint(x: 0, y: 0.00222 * height),
                              control1: CGPoint(x: 0.44754 * width, y: 0.0971 * height),
                              control2: CGPoint(x: 0.17707 * width, y: -0.01736 * height))

                path.addCurve(to: CGPoint(x: 0, y: 0.99921 * height),
                              control1: CGPoint(x: 0, y: 0.13298 * height),
                              control2: CGPoint(x: 0, y: 0.99921 * height))

                path.addLine(to: CGPoint(x: 0.99993 * width, y: 0.99921 * height))

                path.addLine(to: CGPoint(x: 0.99993 * width, y: 0.99993 * height))

                path.closeSubpath()

        return path;
    }
}

#Preview {
    BackG3()
}

//
//  Line2.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import SwiftUI

struct Line2: View {
    var body: some View {
        Shape7().stroke(Color.pink, lineWidth: 0.7191506624221802)
            .frame(width: 100, height: 150)
            .offset(x:210, y:80)
            .opacity(0.5)
            .blendMode(.overlay)
    }
}

struct Shape7: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

struct Line2_Previews: PreviewProvider {
    static var previews: some View {
        Line2()
    }
}

//
//  AnimatedMeshGradient.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-10-01.
//

import SwiftUI

struct AnimatedMeshGradient: View {
    @State private var appear = false
    @State private var appear2: Bool = false
    
    
    var body: some View {
        MeshGradient(
            width: 3,
            height:3,
            points: [
                .init(x: 0, y: 0), .init(x: 0.5, y: 0), .init(x: 1, y: 0),
                .init(x: 0, y: 0.5), .init(x: 0.5, y: 0.5), .init(x: 1, y: 0.5),
                .init(x: 0, y: 1), .init(x: 0.5, y: 1), .init(x: 1, y: 1)
//                [0.0, 0.0], [appear2 ? 0.5:1.0,0.0], [1.0,0.0],
//                [0.0, 0.5], [appear2 ? [0.1, 0.5]:[0.8, 0.2],[1.0, -0.5],
//                [0.0, 1.0], [appear2 ? 0.5:1.0,1.0], [0.0,1.0],
        ], colors:[
            .blue, .purple, .indigo,
            .orange, .red, .yellow,
            .green, .yellow, .red
        ])
    }
}

#Preview {
    AnimatedMeshGradient()
        .ignoresSafeArea()
}

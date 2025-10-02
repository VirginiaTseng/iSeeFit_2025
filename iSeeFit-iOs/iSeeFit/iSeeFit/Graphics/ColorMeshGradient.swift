//
//  ColorMeshGradient.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-10-01.
//

import SwiftUI

struct ColorMeshGradient: View {
    @State private var appear = false
    @State private var appear2: Bool = false
    
    var body: some View {
        //mesh_gradient_1()
        //mesh_gradient_2()
        //mesh_gradient_3()
        //mesh_gradient_4()
        mesh_gradient_5()
    }
    
    
    fileprivate func mesh_gradient_5() -> some View {
        return
        
        MeshGradient(
            width: 3,
            height:3,
            points: [
                [0.0, 0.0], [appear2 ? 0.5:1.0, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear ? [0.1, 0.5]:[0.8, 0.2], [1.0, -0.5],
                [0.0, 1.0], [1.0 , appear2 ? 2.0:1.0], [1.0, 1.0],
            ], colors:[
                appear2 ? .red: .mint, appear2 ? .yellow: .cyan, .orange,
                appear ? .blue: .red, appear ? .cyan:.white, appear ? .red: .purple,
                appear ? .red : .cyan,  appear ? .mint: .blue, .orange, appear2 ? .red : .blue
            ])
        .onAppear() {
            //appear = true
            withAnimation(.easeIn(duration: 1).repeatForever(autoreverses:  true)) {
                appear.toggle()
            }
            withAnimation(.easeIn(duration: 2).repeatForever(autoreverses:  true)) {
                appear2.toggle()
            }
        }
    }
    
    
    
    fileprivate func mesh_gradient_4() -> some View {
        return
        
        MeshGradient(
            width: 3,
            height:3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear ? [0.5, 0.5]:[0.8, 0.2], [1.0, 0.5],
                [0.0, 1.0], [appear ? 0.5:1.0, 1.0], [1.0, 1.0],
            ], colors:[
                .blue, .purple, .indigo,
                .orange, appear2 ? .orange:.white, .blue,
                .yellow, .green, appear ? .green: .mint
            ])
        .onAppear() {
            //appear = true
            withAnimation(.easeIn(duration: 0.5).repeatForever(autoreverses:  true)) {
                appear.toggle()
            }
            withAnimation(.easeIn(duration: 5).repeatForever(autoreverses:  true)) {
                appear2.toggle()
            }
        }
    }
    

    
    fileprivate func mesh_gradient_1() -> MeshGradient {
        return MeshGradient(
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
                .orange, .white, .blue,
                .yellow, .green, .mint
            ])
    }
    
    fileprivate func mesh_gradient_2() -> MeshGradient {
        return MeshGradient(
            width: 3,
            height:3,
            points: [
                .init(x: 0, y: 0), .init(x: 0.5, y: 0), .init(x: 1, y: 0),
                .init(x: 0, y: 0.5), .init(x: 0.5, y: 0.5), .init(x: 1, y: 0.5),
                .init(x: 0, y: 1), .init(x: 0.5, y: 1), .init(x: 1, y: 1)
            ], colors:[
                .black, .black, .black,
                .blue, .blue, .blue,
                .green, .green, .green
            ])
    }
    
    
    fileprivate func mesh_gradient_3() -> MeshGradient {
        return MeshGradient(
            width: 3,
            height:3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.8, 0.2], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ], colors:[
                .blue, .purple, .indigo,
                .orange, .white, .blue,
                .yellow, .green, .mint
            ])
    }
    
}

#Preview {
    ColorMeshGradient()
        .ignoresSafeArea()
}

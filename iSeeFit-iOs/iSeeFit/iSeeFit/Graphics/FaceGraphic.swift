//
//  FaceGraphic.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-18.
//

import SwiftUI

struct FaceGraphic: View {
    @State var appear: Bool = false
    @Binding var selection: Int
    @State var active: Bool = false
    
    
    var body:some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops:[
                .init(color: Color.brown, location:0),
                .init(color: Color.blue, location:0.73),
                .init(color: Color.purple, location:1) ]),
                           startPoint: UnitPoint(x: 0.54, y: 0.092),
                           endPoint:UnitPoint(x: 0.55, y: 1.123))
//            .overlay(
//                InsideFace1()
//            )
//            .overlay(
//                InsideFace2()
//            )
//            .overlay(
//                 InsideFace3()
//             )
//            .overlay(
//                 InsideFace4()
//             )
//            .overlay(
//                 InsideFace5()
//             )
//            .overlay(
//                Line1()
//            )
//            .overlay(
//               Line2()
//            )
//            .overlay(
//                Stars().opacity(0)
//            }
//            .mask(Facemask())
            .frame(width: 522, height: 405, alignment: .center)
            .offset(x: 0, y: -280)
            
            ZStack {
//                PurplePlanet()
//                    .offset(x: appear? 0:50 y: apear? 0: 20)
//                YellowPlanet()
//                              .offset(x: appear? 0:100 y: apear? 0: 100)
                RedPlanet()  .offset(x: appear ? -70 : 100)
            }
        }
        .opacity(active ? 1 : 0)
        .onAppear {
            update()
//            withAnimation(.linear(duration: 10)) {
//                appear = true
//            }
             
        }
        .onChange(of: selection, perform: { value in
            update()
        })
//
    }
    
    func update(){
        if selection == 0 {
            withAnimation(.easeOut(duration: 10)) {
                        appear = true
                    }
            withAnimation {
                active = true
            }
        
        }else{
            withAnimation(.easeOut(duration: 10)) {
                      appear = false
                  }
          withAnimation {
              active = false
          }
        }
    }
    
}



struct SaturnRing: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        path.move(to: CGPoint(x: 0.69817 * width, y: 0.35633 * height))

        path.addCurve(to: CGPoint(x: 0.83072 * width, y: 0.54354 * height),
                      control1: CGPoint(x: 0.75265 * width, y: 0.41535 * height),
                      control2: CGPoint(x: 0.79837 * width, y: 0.47971 * height))

        path.addCurve(to: CGPoint(x: 0.87736 * width, y: 0.77254 * height),
                      control1: CGPoint(x: 0.87497 * width, y: 0.63087 * height),
                      control2: CGPoint(x: 0.89146 * width, y: 0.7118 * height))

        path.addCurve(to: CGPoint(x: 0.75342 * width, y: 0.87666 * height),
                      control1: CGPoint(x: 0.86327 * width, y: 0.83329 * height),
                      control2: CGPoint(x: 0.81947 * width, y: 0.87008 * height))

        path.addCurve(to: CGPoint(x: 0.69313 * width, y: 0.87495 * height),
                      control1: CGPoint(x: 0.73468 * width, y: 0.87852 * height),
                      control2: CGPoint(x: 0.71447 * width, y: 0.87792 * height))

        path.addCurve(to: CGPoint(x: 0.51515 * width, y: 0.80861 * height),
                      control1: CGPoint(x: 0.63927 * width, y: 0.86744 * height),
                      control2: CGPoint(x: 0.57819 * width, y: 0.84483 * height))

        path.addCurve(to: CGPoint(x: 0.27073 * width, y: 0.59929 * height),
                      control1: CGPoint(x: 0.42714 * width, y: 0.7583 * height),
                      control2: CGPoint(x: 0.3508 * width, y: 0.69929 * height))

        path.closeSubpath()

        return path
    }
}



struct FaceGraphic_Previews: PreviewProvider {
    static var previews: some View {
        FaceGraphic(selection: .constant(0))
    }
}

struct Star: View {
    var body: some View {
        Circle().fill(Color.white)
            .frame(width: 3.4, height: 3.4)
            .offset(x: 200, y: 0)
            .shadow(color: Color.white, radius : 2, x:0, y:0)
            .opacity(0.6)
    }
}

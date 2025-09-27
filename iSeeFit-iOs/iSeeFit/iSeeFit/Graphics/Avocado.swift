import SwiftUI

// 牛油果主体形状
struct AvocadoBody: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // 牛油果外轮廓
        path.move(to: CGPoint(x: 0.3 * width, y: 0.1 * height))
        
        path.addCurve(to: CGPoint(x: 0.7 * width, y: 0.1 * height),
                      control1: CGPoint(x: 0.4 * width, y: 0.05 * height),
                      control2: CGPoint(x: 0.6 * width, y: 0.05 * height))
        
        path.addCurve(to: CGPoint(x: 0.8 * width, y: 0.4 * height),
                      control1: CGPoint(x: 0.75 * width, y: 0.2 * height),
                      control2: CGPoint(x: 0.8 * width, y: 0.3 * height))
        
        path.addCurve(to: CGPoint(x: 0.7 * width, y: 0.9 * height),
                      control1: CGPoint(x: 0.8 * width, y: 0.6 * height),
                      control2: CGPoint(x: 0.75 * width, y: 0.8 * height))
        
        path.addCurve(to: CGPoint(x: 0.3 * width, y: 0.9 * height),
                      control1: CGPoint(x: 0.5 * width, y: 0.95 * height),
                      control2: CGPoint(x: 0.4 * width, y: 0.95 * height))
        
        path.addCurve(to: CGPoint(x: 0.2 * width, y: 0.4 * height),
                      control1: CGPoint(x: 0.25 * width, y: 0.8 * height),
                      control2: CGPoint(x: 0.2 * width, y: 0.6 * height))
        
        path.addCurve(to: CGPoint(x: 0.3 * width, y: 0.1 * height),
                      control1: CGPoint(x: 0.2 * width, y: 0.3 * height),
                      control2: CGPoint(x: 0.25 * width, y: 0.2 * height))
        
        path.closeSubpath()
        
        return path
    }
}

// 牛油果核形状
struct AvocadoSeed: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // 椭圆形核
        path.addEllipse(in: CGRect(x: 0.35 * width, y: 0.3 * height, 
                                 width: 0.3 * width, height: 0.4 * height))
        
        return path
    }
}

// 牛油果叶子形状
struct AvocadoLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // 叶子形状
        path.move(to: CGPoint(x: 0.5 * width, y: 0.1 * height))
        
        path.addCurve(to: CGPoint(x: 0.2 * width, y: 0.3 * height),
                      control1: CGPoint(x: 0.3 * width, y: 0.15 * height),
                      control2: CGPoint(x: 0.25 * width, y: 0.25 * height))
        
        path.addCurve(to: CGPoint(x: 0.8 * width, y: 0.3 * height),
                      control1: CGPoint(x: 0.4 * width, y: 0.4 * height),
                      control2: CGPoint(x: 0.6 * width, y: 0.4 * height))
        
        path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.1 * height),
                      control1: CGPoint(x: 0.75 * width, y: 0.25 * height),
                      control2: CGPoint(x: 0.7 * width, y: 0.15 * height))
        
        path.closeSubpath()
        
        return path
    }
}
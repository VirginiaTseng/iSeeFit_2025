//
//  OnboardingView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-17.
//

import SwiftUI
//import SwiftUIX

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
  //  @State private var currentPage = 0
    @State var selection = 0

    var body: some View {
        ZStack {
            background
            
            TabView(selection: $selection) {
                OnboardingCardView().tag(0)
                OnboardingCardView().tag(1)
                OnboardingCardView().tag(2)
                
                CardView(title: "Welcome", description: "Discover the app", imageName: "1").tag(3)
//                CardView(title: "Welcome", description: "Discover the app", imageName: "2").tag(1)
            }
            .tabViewStyle(PageTabViewStyle())
            .overlay(
                Button(action: {
                    hasSeenOnboarding = true // 记录用户已完成引导
                }) {
                    Text("Get Started")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                    
//                    Button(action: {
//                        self.hasSeenOnboarding = true
//                    }) {
//                        Text("Get Started")
//                    }
                }
                .opacity(selection == 3 ? 1 : 0) // 只有到最后一页才显示
            )
            
            .background(
                ZStack{
                    FaceGraphic(selection: $selection) //。constant（0）
                    FaceGraphic(selection: $selection)
//                    Blob2Graphic(selection: $selection)
                }
            )
            
            
//            Text("\(selection)")
//                .foregroundColor(.white)
        }
        
     
        
        
//        TabView(selection: $currentPage) {
//            OnboardingPageView(title: "Welcome", description: "Discover the app", imageName: "1")
//                .tag(0)
//            OnboardingPageView(title: "Track Your Mood", description: "Easily log your feelings", imageName: "2")
//                .tag(1)
//            OnboardingPageView(title: "Join the Community", description: "Connect with others", imageName: "3")
//                .tag(2)
//        }
//        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
//        .overlay(
//            Button(action: {
//                hasSeenOnboarding = true // 记录用户已完成引导
//            }) {
//                Text("Get Started")
//                    .fontWeight(.bold)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                    .padding()
//            }
//            .opacity(currentPage == 2 ? 1 : 0) // 只有到最后一页才显示
//        )
    }
    
//    var background: some View {
//        Color.black
//            .opacity(0.75)
//    }
    
    var background: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops:[
                    .init(color: Color.pink, location: 0),
                    .init(color: Color.purple, location: 1)]),
                startPoint: UnitPoint(x:0.5000000291053439, y:1.0838161507153998e-8),
                endPoint: UnitPoint(x:-0.002089660354856915, y:0.976613295904758))
            .ignoresSafeArea()
            .overlay(ZStack {
                Wave()
                Wave1()
            })  //overlay, background
           
        }
         }
}


struct CardView: View {
    var title: String
    var description: String
    var imageName: String

    var body: some View {
        VStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct OnboardingPageView: View {
    var title: String
    var description: String
    var imageName: String

    var body: some View {
        VStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}


// 预览
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

struct OnboardingCardView: View {
    var body: some View {
        VStack (alignment: .leading, spacing: 16){
            Text("iSeeFit")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color.white.opacity(0.7))
            
//            Text("Gain Inner Peace and Mental Health")
//                .font(.largeTitle)
//                .bold()
            
            LinearGradient(
                        gradient: Gradient(stops:[
                            .init(color: Color.blue, location: 0),
                            .init(color: Color.white, location: 0.563),
                            .init(color: Color.pink, location: 1)]),
                        startPoint: UnitPoint(x:1.01354, y:1.0175),
                        endPoint: UnitPoint(x:-1.110223e-16, y:0))
            .frame(height: 140)
            .mask(Text("Gain Inner Peace \nand \nMental Health")
                .font(.largeTitle)
                .frame(minWidth:.infinity, alignment: .leading )
                .bold())
            
            Text("Utilize your mood to track your well-being. Find out more about how it works. And most importantly, have fun!")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.7))
            
            //                Button(action: {
            //                    self.hasSeenOnboarding = true
            //                }) {
            //                    Text("Get Started")
            //                }
        }
        .padding(30)
        .background(LinearGradient(
            gradient: Gradient(stops:[
                .init(color: Color.purple, location: 0),
                .init(color: Color.clear, location: 1)]),
            startPoint: UnitPoint(x:0.49999988837676157, y:2.9497591284275417e-15),
            endPoint: UnitPoint(x:0.499999888443689973, y:0.9363635917132408)))
        .mask(RoundedRectangle(cornerRadius: 30,
                               style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 30,
                                  style: .continuous).stroke(LinearGradient(
                                    gradient: Gradient(stops:[
                                        .init(color: Color.white, location: 0),
                                        .init(color: Color.clear, location: 1)]),
                                    startPoint: UnitPoint(x:0.5, y:-3.06162e-17),
                                    endPoint: UnitPoint(x:0.5, y:0.5)), lineWidth:2)
                                    .blendMode(.overlay)
                                    //.blur(radius: 5)
        )
//        .background(
//            VisualEffectBlurView(blurStyle: .systemUltraThinMaterialDark)
//                .mask(RoundedRectangle(cornerRadius: <#T##CGFloat#>, style: .continuous)
//                    .fill(LinearGradient(
//                        gradient: Gradient(colors:[Color.red, Color.blue.opacity(0)]),
//                        startPoint: .top,
//                        endPoint:.bottom)))
//        )
        .padding(20)
    }
}

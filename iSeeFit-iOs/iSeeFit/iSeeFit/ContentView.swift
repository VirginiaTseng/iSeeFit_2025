//
//  ContentView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-17.
//

import SwiftUI
//import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    
    var body: some View {
        // debug unmask code below
//        Button("Reset Onboarding") {
//            UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
//            hasSeenOnboarding = false
//        }
        
        
        if hasSeenOnboarding {
            TabView(selection: $selectedTab) {
                        HomeView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .tag(0)
                        
                        MapView()
                            .tabItem {
                                Image(systemName: "map.fill")
                                Text("Map")
                            }
                            .tag(1)
                        
//                        EmergencyView()
//                            .tabItem {
//                                Image(systemName: "exclamationmark.triangle.fill")
//                                Text("Emergency")
//                            }
//                            .tag(2)
//
                        FoodCalorieView()
                            .tabItem {
                                Image(systemName: "fork.knife")
                                Text("Food")
                            }
                            .tag(2)
                        CommunityView()
                            .tabItem {
                                Image(systemName: "heart.fill")
                                Text("Community")
                            }
                            .tag(3)
                        
//                        ProfileView()
//                            .tabItem {
//                                Image(systemName: "person.fill")
//                                Text("Profile")
//                            }
//                            .tag(4)
                        EmergencyView2()
                            .tabItem {
                                Image(systemName: "phone.circle.fill")
                                Text("Emergency")
                            }.tag(4)
                 
                    }
                    .accentColor(.purple)
                    .preferredColorScheme(.light)
            
//            VStack {
//                //MainView() // 进入主页面
//                HomeView()
//                NavigationLink(destination: LoginView()) {
//                        Text("Login")
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                    .padding()
//                                
//                NavigationLink(destination: LoginView()) {
//                    Text("Go to Home")
//                        .padding()
//                        .frame(maxWidth: .infinity)
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//                .padding()
//            }
        } else {
            OnboardingView() // 进入引导页
        }
        
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}



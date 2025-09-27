//
//  ContentView.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-17.
//

import SwiftUI
import AVFoundation
import Vision
//import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    

    
    var body: some View {
        // debug unmask code below
//        Button("Reset Onboarding") {
//            UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
//            hasSeenOnboarding = false
//        }
        
       if !hasSeenIntro{
           LaunchVideoView(onFinish: { hasSeenIntro = true })
       } else if !hasSeenOnboarding {
           OnboardingView()
       } else if hasSeenOnboarding {
            TabView(selection: $selectedTab) {
                
                        TodaysMemoryView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .tag(0)
                            
                        FoodCalorieView()
                            .tabItem {
                                Image(systemName: "fork.knife")
                                Text("Food")
                            }
                            .tag(1)
                            
                  
                        
                        WeightChartView()
                            .tabItem {
                                Image(systemName: "clock").symbolRenderingMode(.palette)
                                Text("Today")
                            }
                            .tag(2)
                        
//                        EmergencyView()
//                            .tabItem {
//                                Image(systemName: "exclamationmark.triangle.fill")
//                                Text("Emergency")
//                            }
//                            .tag(2)
//

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
                        SettingsView()
                            .tabItem {
                                Image(systemName: "person.crop.circle")
                                Text("Profile")
                            }.tag(4)
                        HomeView()
                            .tabItem {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .tag(5)
                        TodayView().tabItem {
                            Image(systemName: "house.fill")
                            Text("Timeline")
                        }
                        .tag(7)
                        
                        //PoseDetectionView()
                        VideoView()
                            .tabItem {
                                Image(systemName: "video.fill")
                                Text("Fitness")
                            }
                            .tag(8)
                
                        FoodHistoryView()
                            .tabItem {
                                Image(systemName: "list.bullet")
                                Text("History")
                            }
                            .tag(6)     
                    }
                    .accentColor(.purple)
                    .preferredColorScheme(.light)
                    .onAppear {
                        notificationManager.requestAuthorization()
                    }
            
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
        }
        
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}



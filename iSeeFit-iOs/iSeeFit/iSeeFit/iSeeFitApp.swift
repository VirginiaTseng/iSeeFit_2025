//
//  iSeeFitApp.swift
//  iSeeFit
//
//  Created by Virginia Zheng on 2025-02-17.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct iSeeFitApp: App {
    @StateObject private var notificationManager = NotificationManager.shared
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
   // let locationManager = LocationManager()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environmentObject(WeatherAlertService(
//                    locationManager: locationManager,
//                    notificationManager: notificationManager
//                ))
                .onAppear {
                    notificationManager.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

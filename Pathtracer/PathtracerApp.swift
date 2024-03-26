//
//  PathtracerApp.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//
import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //override for app launch
        return true
    }
}

func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    //called when a new scene is created
    
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
}

func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>){
    //called when user discards scene session
}




struct PathtracerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

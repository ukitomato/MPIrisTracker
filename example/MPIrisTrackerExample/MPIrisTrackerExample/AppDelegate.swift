//
//  AppDelegate.swift
//  MPIrisTrackerExample
//
//  Created by Yuki Yamato on 2021/05/05.
//

import SwiftUI
import AVFoundation
import Resolver

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MPTrackerDelegate {
    var tracker: MPIrisTracker = MPIrisTracker()
    var image: Image = Image(uiImage: UIImage())
    @ObservedObject var irisTrackController: IrisTrackController = Resolver.resolve()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        tracker.delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


    func faceMeshDidUpdate(_ irisTracker: MPIrisTracker!, didOutputLandmarks landmarks: [MPLandmark]!, timestamp: Int) {
//        print(String(format: "[TS:%lld] Number of face landmarks: %d", timestamp, landmarks!.count))
        DispatchQueue.main.async {
            self.irisTrackController.faceMesh = landmarks
        }
    }

    func irisTrackingDidUpdate(_ irisTracker: MPIrisTracker!, didOutputLandmarks landmarks: [MPLandmark]!, timestamp: Int) {
//        print(String(format: "[TS:%lld] Number of landmarks on iris: %d", timestamp, landmarks!.count))
        DispatchQueue.main.async {
            self.irisTrackController.irisLandmarks = landmarks
        }
    }


    func frameWillUpdate(_ irisTracker: MPIrisTracker!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!, timestamp: Int) {
        if let image = IrisTrackController.imageFromSampleBuffer(pixelBuffer) {
            DispatchQueue.main.async {
                self.irisTrackController.image = image
            }
        }
    }

    func frameDidUpdate(_ irisTracker: MPIrisTracker!, didOutputPixelBuffer pixelBuffer: CVPixelBuffer!) {
        // Get modified image frame for landmarks
        if let image = IrisTrackController.imageFromSampleBuffer(pixelBuffer) {
            DispatchQueue.main.async {
                self.irisTrackController.annotatedImage = image
            }
        }
    }
}


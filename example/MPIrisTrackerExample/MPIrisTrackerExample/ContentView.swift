//
//  ContentView.swift
//  MPIrisTrackerExample
//
//  Created by Yuki Yamato on 2021/05/05.
//

import SwiftUI
import Resolver

struct ContentView: View {
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    @ObservedObject var irisTrackController: IrisTrackController = Resolver.resolve()

    var body: some View {
        VStack {
            HStack {
                if irisTrackController.image != nil {
                    Image(uiImage: UIImage(cgImage: irisTrackController.image!))
                        .resizable()
                        .scaledToFit()
                }
                if irisTrackController.annotatedImage != nil {
                    Image(uiImage: UIImage(cgImage: irisTrackController.annotatedImage!))
                        .resizable()
                        .scaledToFit()
                }
            }
            Text(irisTrackController.irisLandmarks.isEmpty ? ""
            : "Right Eye: x=\(String(format: "%01.4f", irisTrackController.irisLandmarks[0].x)) y=\(String(format: "%01.4f", irisTrackController.irisLandmarks[0].y))")
            Text(irisTrackController.irisLandmarks.isEmpty ? ""
            :  "Left Eye: x=\(String(format: "%01.4f", irisTrackController.irisLandmarks[5].x)) y=\(String(format: "%01.4f", irisTrackController.irisLandmarks[5].y))")

        }
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            .onAppear() {
            appDelegate.tracker.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

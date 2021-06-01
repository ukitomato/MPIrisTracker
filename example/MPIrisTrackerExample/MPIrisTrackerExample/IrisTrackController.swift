//
//  IrisTrackController.swift
//  MPIrisTrackerExample
//
//  Created by Yuki Yamato on 2021/05/28.
//

import SwiftUI
import Resolver
import os
import AVFoundation


public class IrisTrackController: ObservableObject {
    @Published var irisLandmarks = [MPLandmark]()
    @Published var faceMesh = [MPLandmark]()
    @Published var image: CGImage?
    @Published var annotatedImage: CGImage?

    public static func imageFromSampleBuffer(_ pixelBuffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let context = CIContext()
        if let image = context.createCGImage(ciImage, from: imageRect) {
            return image
        }
        return nil
    }
}

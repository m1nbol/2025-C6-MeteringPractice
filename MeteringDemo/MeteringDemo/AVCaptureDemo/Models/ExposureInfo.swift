//
//  ExposureInfo.swift
//  
//
//  Created by 이현주 on 9/22/25.
//

import SwiftUI
import AVFoundation

struct ExposureInfo {
    let iso: Float
    let exposureDuration: Double
    let aperture: Float
    let ev: Double
    let bias: Float
    let offset: Float
    let mode: AVCaptureDevice.ExposureMode
}


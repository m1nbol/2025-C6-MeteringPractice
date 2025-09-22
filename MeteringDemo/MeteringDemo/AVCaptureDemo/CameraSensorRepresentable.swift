//
//  CameraSensorRepresentable.swift
//  AVCaptureDeviceDemo
//
//  Created by 이현주 on 9/17/25.
//

import SwiftUI

struct CameraSensorRepresentable: UIViewRepresentable {
    @Binding var iso: Float
    @Binding var exposureDuration: Double
    @Binding var aperture: Float
    @Binding var ev: Double
    @Binding var bias: Float
    @Binding var offset: Float

    func makeUIView(context: Context) -> CameraSensorReaderView {
        let view = CameraSensorReaderView()
        view.isHidden = true // 화면에는 보이지 않음

        view.onExposureUpdate = { info in
            DispatchQueue.main.async {
                self.iso = info.iso
                self.exposureDuration = info.exposureDuration
                self.aperture = info.aperture
                self.ev = info.ev
                self.bias = info.bias
                self.offset = info.offset
            }
        }
        return view
    }

    func updateUIView(_ uiView: CameraSensorReaderView, context: Context) {}
}


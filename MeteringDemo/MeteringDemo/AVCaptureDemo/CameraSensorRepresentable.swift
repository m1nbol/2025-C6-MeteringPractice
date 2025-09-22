//
//  CameraSensorRepresentable.swift
//  AVCaptureDeviceDemo
//
//  Created by 이현주 on 9/17/25.
//

import SwiftUI

struct CameraSensorRepresentable: UIViewRepresentable {
    @Binding var iso: Float
    @Binding var exposure: Double
    @Binding var offset: Float

    func makeUIView(context: Context) -> CameraSensorReaderView {
        let view = CameraSensorReaderView()
        view.isHidden = true // 화면에는 보이지 않음

        view.onExposureUpdate = { isoValue, exposureValue, offsetValue in
            DispatchQueue.main.async {
                self.iso = isoValue
                self.exposure = exposureValue
                self.offset = offsetValue
            }
        }
        return view
    }

    func updateUIView(_ uiView: CameraSensorReaderView, context: Context) {}
}


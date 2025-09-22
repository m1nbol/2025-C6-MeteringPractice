//
//  LightMeterOnlySensorView.swift
//  AVCaptureDeviceDemo
//
//  Created by 이현주 on 9/17/25.
//

import SwiftUI

struct LightMeterOnlySensorView: View {
    @State private var iso: Float = 0
    @State private var exposure: Double = 0
    @State private var offset: Float = 0

    var body: some View {
        VStack(spacing: 12) {
            Text("ISO: \(iso, specifier: "%.1f")")
            Text("Exposure: \(exposure, specifier: "%.4f")s")
            Text("Offset(EV): \(offset, specifier: "%.2f")")

            if offset < -1 {
                Text("주변이 어두움 🌑").foregroundColor(.blue)
            } else if offset > 1 {
                Text("주변이 밝음 ☀️").foregroundColor(.orange)
            } else {
                Text("적정 노출 👍").foregroundColor(.green)
            }

            // 센서 실행 (화면에 보이지 않음)
            CameraSensorRepresentable(iso: $iso, exposure: $exposure, offset: $offset)
                .frame(width: 0, height: 0) // UI에는 표시 안 됨
        }
        .padding()
    }
}


#Preview {
    LightMeterOnlySensorView()
}

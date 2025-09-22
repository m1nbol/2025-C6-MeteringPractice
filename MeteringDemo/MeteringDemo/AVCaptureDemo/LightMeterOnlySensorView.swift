//
//  LightMeterOnlySensorView.swift
//  AVCaptureDeviceDemo
//
//  Created by 이현주 on 9/17/25.
//

import SwiftUI

struct LightMeterOnlySensorView: View {
    let elevationDeg: Double
    let cloudCover: Double?
    let isSunUp: Bool
    
    @State private var iso: Float = 0
    @State private var exposureDuration: Double = 0
    @State private var aperture: Float = 0
    @State private var ev: Double = 0
    @State private var bias: Float = 0
    @State private var offset: Float = 0
    
    @State private var evFused: Double = 0
    @State private var wCam: Double = 0.5
    @State private var advice: PhotoAdvice = .empty

    private let evFilter = EVFilter(alpha: 0.3)
    
    var body: some View {
        VStack(spacing: 12) {
            Text("ISO: \(iso, specifier: "%.1f")")
            Text("Exposure: \(exposureDuration, specifier: "%.4f")s")
            Text("Aperture: f/\(aperture, specifier: "%.1f")")
            Text("EV (계산값): \(ev, specifier: "%.2f")")
            Text("Bias (EV 보정): \(bias, specifier: "%.2f")")
            Text("Offset (목표 대비 차이): \(offset, specifier: "%.2f")")
                        
            VStack(spacing: 6) {
                Text("EV_fused(융합): \(evFused, specifier: "%.2f")")
                    .font(.headline)
                Text(String(format: "w_cam(센서 가중): %.0f%% · w_model: %.0f%%", wCam * 100, (1 - wCam) * 100))
                    .font(.footnote).foregroundStyle(.secondary)
            }

            if offset < -1 {
                Text("주변이 어두움 🌑").foregroundColor(.blue)
            } else if offset > 1 {
                Text("주변이 밝음 ☀️").foregroundColor(.orange)
            } else {
                Text("적정 노출 👍").foregroundColor(.green)
            }

            // 센서 실행 (프리뷰는 보이지 않음)
            CameraSensorRepresentable(
                iso: $iso,
                exposureDuration: $exposureDuration,
                aperture: $aperture,
                ev: $ev,
                bias: $bias,
                offset: $offset
            )
            .frame(width: 0, height: 0) // UI에는 표시 안 됨
        }
        .padding()
        .task { fuseNow() }
        .onChange(of: ev) { fuseNow() }
        .onChange(of: offset) { fuseNow() }
        .onChange(of: isSunUp) { fuseNow() }
        .onChange(of: elevationDeg) { fuseNow() }
        .onChange(of: cloudCover) { fuseNow() }
    }
    
    /// 센서 EV와 모델 EV를 융합하고, EMA로 평활한 뒤 가이드를 갱신
    private func fuseNow() {
        guard exposureDuration > 0, aperture > 0 else { return }
        
        let baseAdvice = PhotoAdvice.build(elevationDeg: elevationDeg,
                                           cloudCover: cloudCover,
                                           isSunUp: isSunUp)
        let modelEV = baseAdvice.ev100
        
        // 센서 단독 모드 여부: 밤 또는 모델 EV가 사실상 0
        let isSensorOnly = (isSunUp == false) || (elevationDeg <= -0.833) || (modelEV < 1.0)
        
        if isSensorOnly {
            // --- 센서 단독 모드 ---
            let clampedOffset = max(-2.0, min(2.0, Double(offset)))
            let targetEV = ev - 0.5 * clampedOffset
            let smooth = evFilter.push(targetEV)
            
            evFused = max(0, smooth)
            wCam = 1.0                                    // 표시/로직 모두 센서 100%
            
            var out = baseAdvice                           // baseAdvice는 ev100=0일 수 있음
            out.ev100 = evFused                           // 센서 기반 EV로 덮어쓰기
            out.lightScore = Int(round(min(10, max(0, (evFused - 5) / 1.0))))
            advice = out
            
            return
        }
        
        // --- 해가 있을 때만: 센서×모델 융합 ---
        let likelyLocked = abs(offset) < 0.15
        let fused = ExposureFusion.fuseEV(measuredEV: ev,
                                          modelEV: modelEV,
                                          offsetEV: offset,
                                          cloudCover: cloudCover,
                                          isLikelyLocked: likelyLocked)
        wCam = fused.wCam
        
        let smooth = evFilter.push(fused.evFused)
        evFused = max(0, smooth)
        
        var out = baseAdvice
        out.ev100 = evFused
        out.lightScore = Int(round(min(10, max(0, (evFused - 5) / 1.0))))
        advice = out
    }
}


#Preview {
    LightMeterOnlySensorView(elevationDeg: 45,
                             cloudCover: 0.2,
                             isSunUp: true)
}

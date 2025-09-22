//
//  ExposureFusion.swift
//  MeteringDemo
//
//  Created by BoMin Lee on 9/22/25.
//

import AVFoundation

struct ExposureFusion {
    /// 센서 EV와 모델 EV를 동적으로 융합해 EV100을 반환
    static func fuseEV(measuredEV: Double,
                       modelEV: Double,
                       offsetEV: Float,              // exposureTargetOffset (EV)
                       cloudCover: Double?,          // 0~1
                       isLikelyLocked: Bool) -> (evFused: Double, wCam: Double) {
        let cc = min(max(cloudCover ?? 0, 0), 1)

        // 1) offset 기반 센서 신뢰도: 0EV 근접할수록 ↑
        //    0EV -> 1.0, 1EV -> ~0.5, 2EV -> ~0.33
        let offsetReliability = 1.0 / (1.0 + pow(Double(abs(offsetEV)), 1.2))

        // 2) 구름 많을수록 지역 변동 큼 → 센서 신뢰 ↑ (0.6 ~ 1.0)
        let cloudReliability = 0.6 + 0.4 * Double(cc)

        // 3) 잠금 추정 가산
        let modeBoost = isLikelyLocked ? 1.1 : 0.95

        var wCam = offsetReliability * cloudReliability * modeBoost
        wCam = min(max(wCam, 0.2), 0.9) // 0.2 ≤ w_cam ≤ 0.9

        let fused = wCam * measuredEV + (1.0 - wCam) * modelEV
        return (fused, wCam)
    }
}

/// EV 지수평활 필터
final class EVFilter {
    private var ema: Double?
    private let alpha: Double // 0.25~0.35 권장
    init(alpha: Double = 0.3) { self.alpha = alpha }

    func push(_ value: Double) -> Double {
        if let prev = ema { ema = prev + alpha * (value - prev) }
        else { ema = value }
        return ema!
    }
}

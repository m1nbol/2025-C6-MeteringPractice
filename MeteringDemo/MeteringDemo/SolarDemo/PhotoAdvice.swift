//
//  PhotoAdvice.swift
//  SolarPractice
//
//  Created by BoMin Lee on 9/18/25.
//

import Foundation

struct PhotoAdvice {
    var lightScore: Int           // 0~10
    var ev100: Double             // ISO100 기준 EV 추정
    var shadowLengthRatio: Double // 그림자 길이/피사체 높이 (≈ 1 / tan(elev))
    var suggestedSettings: [String]
    
    static let empty = PhotoAdvice(lightScore: 0, ev100: 0, shadowLengthRatio: 0, suggestedSettings: [])
    
    static func build(elevationDeg: Double, cloudCover: Double?, isSunUp: Bool) -> PhotoAdvice {
        guard isSunUp, elevationDeg > -0.833 else {
            return PhotoAdvice(lightScore: 0, ev100: 0, shadowLengthRatio: 0, suggestedSettings: ["야간: 삼각대 권장, ISO 1600~6400, f/1.8~2.8, 1/5s~30s"])
        }
        let elevRad = elevationDeg * .pi / 180
        let s = max(0.0001, sin(elevRad)) // 고도 기반 광량 프락시
        
        // 기본 EV(맑은 한낮 ≈ 15). 고도에 따라 15 + log2(s)로 스케일.
        let baseEV = 15.0 + log2(s)
        
        // 구름 보정 (간단 모델)
        let cc = cloudCover ?? 0.0 // 0(맑음)~1(완전흐림)
        let cloudPenalty: Double = cc * 2.5 // 완전흐림이면 ~2.5EV 감소
        let ev = max(0, baseEV - cloudPenalty)
        
        // 스코어 (EV 15=10점, EV 5=0점 근사)
        let score = Int(round(min(10, max(0, (ev - 5) / 1.0))))
        
        // 그림자 길이 비(고도 낮으면 그림자 길어짐)
        let shadow = 1.0 / max(0.1, tan(elevRad))
        
        // 상황별 추천 (ISO100 기준 중심, 인물/풍경/역광)
        var tips: [String] = []
        if ev >= 14 {
            tips.append("맑은 낮: ISO100, f/8~f/16, 1/500~1/2000s (움직임 정지)")
        } else if ev >= 12 {
            tips.append("밝은 흐림/금빛 시간: ISO100~200, f/4~f/8, 1/250~1/1000s")
        } else if ev >= 10 {
            tips.append("흐림/그늘: ISO200~400, f/2.8~f/5.6, 1/125~1/500s")
        } else if ev >= 8 {
            tips.append("어스름: ISO400~800, f/1.8~f/2.8, 1/60~1/200s")
        } else {
            tips.append("저조도: ISO800~3200, f/1.4~f/2.8, 1/10~1/60s (손떨림 주의)")
        }
        
        // 장면별 추가(선택)
        if elevationDeg < 10 {
            tips.append("롱섀도우/실루엣 노리기 좋음 (저고도)")
        }
        if cc < 0.2 {
            tips.append("하드 라이트: 반사판 또는 그늘 이동 고려(인물)")
        } else if cc > 0.6 {
            tips.append("소프트 라이트: 피부톤 균일, 역광 보정 최소")
        }
        
        return PhotoAdvice(lightScore: score, ev100: ev, shadowLengthRatio: shadow, suggestedSettings: tips)
    }
}

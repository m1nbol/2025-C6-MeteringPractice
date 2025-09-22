//
//  SunTrackerView.swift
//  SolarPractice
//
//  Created by BoMin Lee on 9/18/25.
//

import SwiftUI
import CoreLocation
import CoreMotion
import WeatherKit

struct SunTrackerView: View {
    @StateObject private var vm = SunTrackerViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // 나침반 + 태양 화살표
            ZStack {
                Circle().stroke(.secondary, lineWidth: 2).frame(width: 180, height: 180)
                // 태양 방향 화살표 (방위각 차로 회전)
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 56, weight: .bold))
                    .rotationEffect(.degrees(vm.relativeBearing)) // 북=0°, 시계방향
                    .animation(.easeInOut(duration: 0.12), value: vm.relativeBearing)
            }
            .frame(height: 200)
            
            // 고도 가이드(위/아래 인디케이터)
            HStack(spacing: 8) {
                Image(systemName: "arrow.up")
                    .opacity(vm.relativeElevation > 5 ? 1 : 0.2)
                Text("고도 Δ \(String(format: "%.1f", vm.relativeElevation))°")
                Image(systemName: "arrow.down")
                    .opacity(vm.relativeElevation < -5 ? 1 : 0.2)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            // 상태 표시
            if vm.sunUp == false {
                Text("지금은 해가 지평선 아래 (해 없음)").foregroundStyle(.secondary)
            } else {
                VStack(spacing: 2) {
                    Text("태양 고도 \(String(format: "%.1f", vm.sunElevation))° · 방위 \(String(format: "%.1f", vm.sunAzimuth))°")
                    Text("기기 헤딩 \(String(format: "%.1f", vm.deviceHeading))° · 피치 \(String(format: "%.1f", vm.devicePitch))°")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
                                    
            // 촬영용 일조량/노출 가이드
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("촬영 노출 가이드").font(.headline)
                    Text("광량 스코어: \(vm.photo.lightScore)/10  ·  EV100 ≈ \(String(format: "%.1f", vm.photo.ev100))")
                    Text("그림자 길이(상대): 약 \(String(format: "%.2f", vm.photo.shadowLengthRatio)) × 피사체 높이")
                        .font(.footnote).foregroundStyle(.secondary)
                    ForEach(vm.photo.suggestedSettings, id: \.self) { line in
                        Text("• \(line)")
                            .lineLimit(5)
                    }
                }
            }
            
            Button {
                Task { await vm.refreshOnce() }
            } label: { Label("업데이트", systemImage: "arrow.clockwise") }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

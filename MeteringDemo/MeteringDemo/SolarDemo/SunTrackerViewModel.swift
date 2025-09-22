//
//  SunTrackerViewModel.swift
//  SolarPractice
//
//  Created by BoMin Lee on 9/18/25.
//

import SwiftUI
import CoreLocation
import CoreMotion
import WeatherKit


final class SunTrackerViewModel: NSObject, ObservableObject {
    // 공개 상태
    @Published var sunUp: Bool = false
    @Published var sunElevation: Double = 0
    @Published var sunAzimuth: Double = 0
    @Published var deviceHeading: Double = 0     // 진북 기준
    @Published var devicePitch: Double = 0       // 위: +, 아래: -
    @Published var relativeBearing: Double = 0   // 태양방위 - 기기헤딩
    @Published var relativeElevation: Double = 0 // 태양고도 - 기기피치
    @Published var photo: PhotoAdvice = .empty
    @Published var cloudCover: Double? = nil  // ⬅️ 추가 (0.0~1.0)
    
    // 내부
    private let locMgr = CLLocationManager()
    private let motion = CMMotionManager()
    private let weather = WeatherService.shared
    
    private var coord: CLLocationCoordinate2D?
    private var timer: Timer?
    
    override init() {
        super.init()
        locMgr.delegate = self
        locMgr.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func start() {
        // 위치 권한
        if locMgr.authorizationStatus == .notDetermined {
            locMgr.requestWhenInUseAuthorization()
        } else {
            locMgr.requestLocation()
        }
        // 헤딩 (진북)
        if CLLocationManager.headingAvailable() {
            locMgr.headingFilter = 1 // 1도 변화마다
            locMgr.startUpdatingHeading()
        }
        // 디바이스 피치
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 30.0
            motion.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: .main) { [weak self] dm, _ in
                guard let self, let dm else { return }
                // pitch: xTrueNorthZVertical 기준 (라디안)
                let pitchDeg = dm.attitude.pitch * 180 / .pi
                self.devicePitch = pitchDeg
                self.updateRelativeAngles()
            }
        }
        // 주기 업데이트(태양 위치/날씨)
        scheduleTimer()
    }
    
    func stop() {
        locMgr.stopUpdatingHeading()
        motion.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
    }
    
    func refreshOnce() async {
        await fetchSunAndPhotoAdvice()
    }
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { await self?.fetchSunAndPhotoAdvice() }
        }
        Task { await fetchSunAndPhotoAdvice() }
    }
    
//    private func updateRelativeAngles() {
//        // bearing: 0~360
//        let rel = fmod((sunAzimuth - deviceHeading) + 360, 360)
//        relativeBearing = rel
//        relativeElevation = sunElevation - devicePitch
//    }
    
    private func updateRelativeAngles() {
        relativeBearing = signedAngleDelta(from: deviceHeading, to: sunAzimuth) // 음수=왼쪽, 양수=오른쪽
        relativeElevation = sunElevation - devicePitch
    }

    /// a(기기 헤딩)에서 to(태양 방위)까지의 서명 각도 델타(-180..+180)
    private func signedAngleDelta(from a: Double, to b: Double) -> Double {
        // 1) 기본 델타
        var d = (b - a).truncatingRemainder(dividingBy: 360)
        // 2) 범위를 -180..+180으로 보정
        if d > 180 { d -= 360 }
        if d <= -180 { d += 360 }
        return d
    }
    
    private func setSun(up: Bool, elev: Double, az: Double) {
        sunUp = up
        sunElevation = elev
        sunAzimuth = az
        updateRelativeAngles()
    }
    
    private func computeSunNow(at coordinate: CLLocationCoordinate2D) -> SunStatus {
        SolarPosition.computeStatus(latitude: coordinate.latitude, longitude: coordinate.longitude, date: Date())
    }
    
    @MainActor
    private func fetchSunAndPhotoAdvice() async {
        guard let c = coord else { return }
        
        // 1) WeatherKit으로 일출/일몰/클라우드
        var cloudCover: Double? = nil
        var isSunUpBySunEvents: Bool? = nil
        do {
            let daily = try await weather.weather(for: .init(latitude: c.latitude, longitude: c.longitude), including: .daily)
            let now = Date()
            if let today = daily.first(where: { Calendar.current.isDate($0.date, inSameDayAs: now) }) {
                if let sr = today.sun.sunrise, let ss = today.sun.sunset {
                    isSunUpBySunEvents = (sr...ss).contains(now)
                }
            }
            let hourly = try await weather.weather(for: .init(latitude: c.latitude, longitude: c.longitude), including: .hourly)
            if let hour = hourly.first {
                cloudCover = hour.cloudCover // 0.0 ~ 1.0
            }
        } catch {
            // 실패해도 넘어감 (각도 계산만으로 동작)
        }
        
        // 2) 태양 위치(각도) 계산 (항상 가능)
        let status = computeSunNow(at: c)
        switch status {
        case .noSun:
            setSun(up: false, elev: status.elevationDeg, az: status.azimuthDeg)
        case .sunUp(let e, let a):
            // SunEvents 기준과 상충하면 고도/굴절 임계(-0.833°)로 최종 판단
            let up = isSunUpBySunEvents ?? (e > -0.833)
            setSun(up: up, elev: e, az: a)
        }
        self.cloudCover = cloudCover
        
        // 3) 촬영용 노출 가이드 계산
        self.photo = PhotoAdvice.build(elevationDeg: sunElevation,
                                       cloudCover: cloudCover,
                                       isSunUp: sunUp)
    }
}

extension SunTrackerViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            coord = last.coordinate
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // trueHeading(진북) 우선, 없으면 magneticHeading 사용
        deviceHeading = (newHeading.trueHeading >= 0) ? newHeading.trueHeading : newHeading.magneticHeading
        updateRelativeAngles()
    }
}

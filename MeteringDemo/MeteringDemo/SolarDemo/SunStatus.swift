//
//  SunStatus.swift
//  SolarPractice
//
//  Created by BoMin Lee on 9/17/25.
//

import Foundation
import CoreLocation
import WeatherKit

enum SunStatus {
    case noSun
    case sunUp(elevationDeg: Double, azimuthDeg: Double)
    var elevationDeg: Double {
        switch self { case .noSun: return -90; case .sunUp(let e, _): return e }
    }
    var azimuthDeg: Double {
        switch self { case .noSun: return 0; case .sunUp(_, let a): return a }
    }
}

@MainActor
func sunStatusNow(at coordinate: CLLocationCoordinate2D) async throws -> SunStatus {
    // 1) SunEvents로 '일출~일몰 구간'인지 빠르게 판단
    let service = WeatherService.shared
    // WeatherKit은 자동으로 위치/날짜에 맞는 데이터 반환 (권한·권역 세팅은 프로젝트에서)
    let dayWeather = try await service.weather(for: .init(latitude: coordinate.latitude, longitude: coordinate.longitude), including: .daily)
    
    // 오늘 항목을 찾되, 현지 타임존 보정은 시스템 기본값에 따름
    let now = Date()
    guard let today = dayWeather.first(where: { Calendar.current.isDate($0.date, inSameDayAs: now) }) else {
        // 오늘 데이터가 없으면 각도 기반으로 직접 판정
        return computeStatusByAngleOnly(coordinate: coordinate, date: now)
    }
    
    let sunrise = today.sun.sunrise
    let sunset  = today.sun.sunset
    
    // 2) 일출~일몰 사이가 아니면 바로 "해 없음"
    if let sr = sunrise, let ss = sunset, !(sr...ss).contains(now) {
        return .noSun
    }
    
    // 3) 각도 계산 (정밀 판정)
    return computeStatusByAngleOnly(coordinate: coordinate, date: now)
}

private func computeStatusByAngleOnly(coordinate: CLLocationCoordinate2D, date: Date) -> SunStatus {
    let pos = SolarPosition.compute(latitude: coordinate.latitude, longitude: coordinate.longitude, date: date)
    // -0.833°(대기 굴절·태양 반지름 보정)보다 크면 '떠있다'로 봄
    if pos.elevationDeg > -0.833 {
        return .sunUp(elevationDeg: pos.elevationDeg, azimuthDeg: pos.azimuthDeg)
    } else {
        return .noSun
    }
}

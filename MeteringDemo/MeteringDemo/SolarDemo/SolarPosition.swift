//
//  SolarPosition.swift
//  SolarPractice
//
//  Created by BoMin Lee on 9/17/25.
//

import Foundation

struct SolarPosition {
    let elevationDeg: Double
    let azimuthDeg: Double
    
    static func computeStatus(latitude lat: Double, longitude lon: Double, date: Date) -> SunStatus {
        let pos = compute(latitude: lat, longitude: lon, date: date)
        return (pos.elevationDeg > -0.833) ? .sunUp(elevationDeg: pos.elevationDeg, azimuthDeg: pos.azimuthDeg) : .noSun
    }
    
    // (이전 답변의 충돌 수정 버전 — 변수명 주의: M_anom 등)
    static func compute(latitude lat: Double, longitude lon: Double, date: Date) -> SolarPosition {
        func deg2rad(_ d: Double) -> Double { d * .pi / 180 }
        func rad2deg(_ r: Double) -> Double { r * 180 / .pi }
        
        let tz = TimeZone(secondsFromGMT: 0)!
        var cal = Calendar(identifier: .gregorian); cal.timeZone = tz
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let Y = c.year!, Mo = c.month!, D = c.day!
        let UT = Double(c.hour ?? 0) + Double(c.minute ?? 0)/60 + Double(c.second ?? 0)/3600
        
        let a = floor(Double((14 - Mo))/12.0)
        let y = Double(Y) + 4800 - a
        let mmm = Double(Mo) + 12*a - 3
        let JDN = Double(D) + floor((153*mmm + 2)/5) + 365*y + floor(y/4) - floor(y/100) + floor(y/400) - 32045
        let JD = JDN + (UT - 12.0)/24.0
        let T = (JD - 2451545.0)/36525.0
        
        let L0 = fmod(280.46646 + T*(36000.76983 + T*0.0003032), 360)
        let M_anom  = 357.52911 + T*(35999.05029 - 0.0001537*T)
        let e  = 0.016708634 - T*(0.000042037 + 0.0000001267*T)
        
        let Mrad = deg2rad(M_anom)
        let C = (1.914602 - T*(0.004817 + 0.000014*T))*sin(Mrad)
              + (0.019993 - 0.000101*T)*sin(2*Mrad)
              + 0.000289*sin(3*Mrad)
        let trueLong = L0 + C
        
        let omega = 125.04 - 1934.136*T
        let lambda = trueLong - 0.00569 - 0.00478*sin(deg2rad(omega))
        
        let U = T/100.0
        let epsilon0 = 23 + (26 + (21.448 - U*(46.815 + U*(0.00059 - U*0.001813)))/60)/60
        let epsilon = epsilon0 + 0.00256*cos(deg2rad(omega))
        
        let delta = asin(sin(deg2rad(epsilon)) * sin(deg2rad(lambda)))
        let yTerm = pow(tan(deg2rad(epsilon/2)), 2)
        let Etime = 4 * rad2deg(yTerm*sin(2*deg2rad(L0))
                     - 2*e*sin(Mrad)
                     + 4*e*yTerm*sin(Mrad)*cos(2*deg2rad(L0))
                     - 0.5*yTerm*yTerm*sin(4*deg2rad(L0))
                     - 1.25*e*e*sin(2*Mrad))
        
        let LST = UT + lon/15.0 + Etime/60.0
        let H = (LST - 12.0) * 15.0
        
        let latRad = deg2rad(lat), HRad = deg2rad(H)
        let sinAlt = sin(latRad)*sin(delta) + cos(latRad)*cos(delta)*cos(HRad)
        let altitude = asin(max(-1, min(1, sinAlt)))
        
        let cosAz = (sin(delta) - sin(latRad)*sin(altitude)) / (cos(latRad)*cos(altitude))
        var azimuth = acos(max(-1, min(1, cosAz)))
        if H > 0 { azimuth = 2*Double.pi - azimuth }
        
        return .init(elevationDeg: rad2deg(altitude),
                     azimuthDeg: fmod(rad2deg(azimuth) + 360.0, 360.0))
    }
}

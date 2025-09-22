//
//  ContentView.swift
//  MeteringDemo
//
//  Created by BoMin Lee on 9/22/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                NavigationLink("Light Meter Sensor View") {
                    LightMeterOnlySensorView(elevationDeg: 45,
                                             cloudCover: 0.2,
                                             isSunUp: true)
                }
                .buttonStyle(.borderedProminent)
                NavigationLink("Sun Tracker View") {
                    SunTrackerView()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    ContentView()
}

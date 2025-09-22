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
                    LightMeterOnlySensorView()
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

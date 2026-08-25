//
//  ContentView.swift
//  ADA_Challenge5_Norton
//

import SwiftUI
import SweatFeatures
import WeatherData

struct ContentView: View {
    var body: some View {
        #if DEBUG
        // 수동 검증에서만 값을 주입한다 (`WeatherHarness`). 인자가 없으면 실제 날씨다.
        if let harness = WeatherHarness.fromLaunchArguments() {
            RootView(weather: WeatherRepository(source: harness))
        } else {
            RootView()
        }
        #else
        RootView()
        #endif
    }
}

#Preview {
    ContentView()
}

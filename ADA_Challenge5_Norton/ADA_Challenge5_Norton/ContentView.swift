//
//  ContentView.swift
//  ADA_Challenge5_Norton
//

import SwiftUI

// 로컬 패키지 링크 확인용 import. 001에서 실제 화면으로 교체된다.
import DesignSystem
import SweatDomain

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

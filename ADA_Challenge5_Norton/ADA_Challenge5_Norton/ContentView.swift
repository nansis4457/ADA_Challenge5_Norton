//
//  ContentView.swift
//  ADA_Challenge5_Norton
//

import SwiftUI
import DesignSystem
import SweatDomain

struct ContentView: View {
    var body: some View {
        #if DEBUG
        // 001에서 실제 화면으로 교체된다.
        // 그때까지는 디자인 시스템 대조용 카탈로그를 띄운다.
        ComponentCatalogView()
        #else
        Color(.clear)
        #endif
    }
}

#Preview {
    ContentView()
}

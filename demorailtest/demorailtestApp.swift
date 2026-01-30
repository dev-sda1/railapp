//
//  demorailtestApp.swift
//  demorailtest
//
//  Created by James on 04/01/2026.
//

import SwiftUI
import SwiftData

@main
struct demorailtestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [RecentlySearched.self, PinnedService.self])
    }
}

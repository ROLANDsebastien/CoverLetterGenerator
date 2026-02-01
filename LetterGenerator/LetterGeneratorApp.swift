//
//  LetterGeneratorApp.swift
//  LetterGenerator
//
//  Created by ROLAND Sébastien on 12/01/2026.
//

import SwiftUI
import SwiftData

@main
struct LetterGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .navigationTitle("")
        }
        .windowToolbarStyle(.unified)
    }
}

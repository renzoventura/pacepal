//
//  pacepalApp.swift
//  pacepal
//
//  Created by Renzo on 8/9/2025.
//

import SwiftUI

@main
struct pacepalApp: App {
    init() {
        ConfigurationService.shared.loadConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            LandingView()
        }
    }
}

//
//  GradientApp.swift
//  Gradient
//
//  Created by Andrew Purdon on 06/03/2025.
//

import SwiftUI

@main
struct GradientApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

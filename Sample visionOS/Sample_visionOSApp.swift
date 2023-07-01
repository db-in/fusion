//
//  Sample_visionOSApp.swift
//  Sample visionOS
//
//  Created by DINEY B ALVES on 7/2/23.
//

import SwiftUI

@main
struct Sample_visionOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.full), in: .full)
    }
}

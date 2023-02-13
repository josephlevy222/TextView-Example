//
//  TextView_ExampleApp.swift
//  TextView-Example
//
//  Created by Joseph Levy on 1/31/23.
//

import SwiftUI

@main
struct TextView_ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(text: aText, nsText: aText.nsAttributedString)
        }
    }
}

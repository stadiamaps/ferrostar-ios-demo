//
//  iOS_DemoApp.swift
//  iOS Demo
//
//  Created by Ian Wagner on 2023-10-09.
//

import SwiftUI

let stadiaMapsAPIKey = Bundle.main.infoDictionary!["STADIAMAPS_API_KEY"] as! String

@main
struct iOS_DemoApp: App {
    var body: some Scene {
        WindowGroup {
            LocationSelectionView()
        }
    }
}

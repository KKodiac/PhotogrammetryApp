//
//  HeadModelMakerApp.swift
//  HeadModelMaker
//
//  Created by Sean Hong on 2022/11/14.
//

import SwiftUI


@main
struct HeadModelMakerApp: App {
    @StateObject var model: PhotogrammetryViewModel = PhotogrammetryViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}

//
//  PhotogrammetryModel.swift
//  HeadModelMaker
//
//  Created by Sean Hong on 2022/11/15.
//

import Foundation
import RealityKit
import SwiftUI



@available(macOS 12.0, *)
extension PhotogrammetrySession.Request.Detail {
    public static var allRawValues: [String] = ["preview", "reduced", "medium", "full", "raw"]
}


@available(macOS 12.0, *)
extension PhotogrammetrySession.Configuration.SampleOrdering {
    public static var allRawValues: [String] = ["unordered", "sequential"]
}

@available(macOS 12.0, *)
extension PhotogrammetrySession.Configuration.FeatureSensitivity {
    public static var allRawValues: [String] = ["normal", "high"]
}

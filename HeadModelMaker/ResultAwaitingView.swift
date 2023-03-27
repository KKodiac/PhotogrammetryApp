//
//  ResultAwaitingView.swift
//  HeadModelMaker
//
//  Created by Sean Hong on 2023/03/27.
//

import SwiftUI

struct ResultAwaitingView: View {
    @ObservedObject var model: PhotogrammetryViewModel
    var body: some View {
        if !model.isProcessingFinished {
            ProgressView(value: model.requestProgress)
            Text("\(model.requestProgress)")
        } else {
            Text("DONE!")
            Text("Checkout your result at \(model.outputFilePath)")
        }
    }
}

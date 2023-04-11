//
//  ResultAwaitingView.swift
//  HeadModelMaker
//
//  Created by Sean Hong on 2023/03/27.
//

import SwiftUI
import QuickLook

struct ResultAwaitingView: View {
    @State var filePathURL: URL? 
    @ObservedObject var model: PhotogrammetryViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        if !model.isProcessingFinished {
            ProgressView()
            Text("Processing...")
        } else {
            Text("DONE!")
            Text("Checkout your result at")
            Text("\(PhotogrammetryViewModel.shared.outputFilePath)")
            Button("Take a quick look!") {
                if let url = URL(string: PhotogrammetryViewModel.shared.outputFilePath) {
                    filePathURL = url
                }
            }
            .quickLookPreview($filePathURL)
            
            Button("Dismiss") {
                isPresented.toggle()
            }
        }
    }
}

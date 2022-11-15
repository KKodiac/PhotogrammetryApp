//
//  ContentView.swift
//  HeadModelMaker
//
//  Created by Sean Hong on 2022/11/14.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    private typealias Configuration = PhotogrammetrySession.Configuration
    private typealias Request = PhotogrammetrySession.Request
    
    @ObservedObject var model: PhotogrammetryViewModel

    private let requirementsLinkURL: String = "https://developer.apple.com/documentation/RealityKit/PhotogrammetrySession"
    
    var body: some View {
        if !PhotogrammetrySession.isSupported {
            HStack {
                Spacer()
                VStack {
                    TextField("Specify input folder url:", text: $model.inputFolderName)
                    TextField("Specify output file name:", text: $model.outputFileName)
                }
                Spacer()
            }
            .toolbar {
                ToolbarItemGroup {
                    Picker("Detail", selection: $model.detailSelection) {
                        ForEach(Request.Detail.allRawValues, id: \.self) { detailValue in
                            Text(detailValue).tag(detailValue)
                        }
                    }
                    Picker("Sample Ordering", selection: $model.sampleOrderingSelection) {
                        ForEach(Configuration.SampleOrdering.allRawValues, id: \.self) { orderValue in
                            Text(orderValue).tag(orderValue)
                        }
                    }
                    Picker("Feature Sensitivity", selection: $model.featureSensitivitySelection) {
                        ForEach(Configuration.FeatureSensitivity.allRawValues, id: \.self) { sensitivityValue in
                            Text(sensitivityValue).tag(sensitivityValue)
                        }
                    }
                }
            }
        } else {
            Text("Your device is not supported!")
            Link("Check if your device meets these requirements.", destination: URL(string: requirementsLinkURL)!)
               
        }
    }
}


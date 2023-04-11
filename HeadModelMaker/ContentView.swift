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
    @State var isPresented: Bool = false
    @ObservedObject var model: PhotogrammetryViewModel

    private let requirementsLinkURL: String = "https://developer.apple.com/documentation/RealityKit/PhotogrammetrySession"
    
    var body: some View {
        if PhotogrammetrySession.isSupported {
            HStack {
                Spacer()
                VStack {
                    Button(action: {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = true
                        if panel.runModal() == .OK {
                            model.inputFolderName = panel.url?.absoluteURL.absoluteString ?? "<none>"
                        }
                    }, label: { Text("Specify input folder URL")})
                    Text("\(model.inputFolderName)")
                    TextField("Specify output file name:", text: $model.outputFileName)
                }
                Spacer()
            }
            .sheet(isPresented: $isPresented) {
                ResultAwaitingView(model: model, isPresented: $isPresented)
                    .frame(width: 500, height: 300)
            }
            .toolbar {
                ToolbarItemGroup {
                    Picker("Details", selection: $model.detailSelection) {
                        ForEach(Request.Detail.allRawValues, id: \.self) { detailValue in
                            Text(detailValue).tag(detailValue)
                        }
                    }
                    
                    Picker("Sample Order", selection: $model.sampleOrderingSelection) {
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
                ToolbarItem {
                    Button("Run") {
                        isPresented.toggle()
                        model.run()
                    }
                }
            }
        } else {
            Text("Your device is not supported!")
            Link("Check if your device meets these requirements.", destination: URL(string: requirementsLinkURL)!)
               
        }
    }
}


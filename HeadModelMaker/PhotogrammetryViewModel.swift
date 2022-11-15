//
//  Photogrammetry.swift
//  HeadModelMaker
//
//  Created by Sean Hong on 2022/11/14.
//

import Foundation
import RealityKit
import Metal

import os

private let logger = Logger(subsystem: "com.seanhong.KKodiac.HeadModelMaker", category: "Photogrammetry")


class PhotogrammetryViewModel: ObservableObject {
    private typealias Configuration = PhotogrammetrySession.Configuration
    private typealias Request = PhotogrammetrySession.Request
    
    static let shared = PhotogrammetryViewModel()

    @Published var inputFolderName: String = ""
    @Published var outputFileName: String = ""
    @Published var isSessionReady: Bool = false
    @Published var isProcessingFinished: Bool = false
    @Published var requestProgress: Double = 0.0
    
    @Published var detailSelection: String = "" {
        didSet {
            self.updatePhotogrammetryDetail(detailSelection)
        }
    }
    @Published var sampleOrderingSelection: String = "" {
        didSet {
            self.updatePhotogrammetrySampleOrdering(sampleOrderingSelection)
        }
    }
    @Published var featureSensitivitySelection: String = "" {
        didSet {
            self.updatePhotogrammetryFeatureSensitivity(featureSensitivitySelection)
        }
    }
    
    private var detail: PhotogrammetrySession.Request.Detail? = nil
    private var sampleOrdering: PhotogrammetrySession.Configuration.SampleOrdering? = nil
    private var featureSensitivity: PhotogrammetrySession.Configuration.FeatureSensitivity? = nil
    
    func update(detail: String, sampleOrdering: String, featureSensitivity: String) {
        self.updatePhotogrammetryDetail(detail)
        self.updatePhotogrammetrySampleOrdering(sampleOrdering)
        self.updatePhotogrammetryFeatureSensitivity(featureSensitivity)
    }
        
    func run() {
        self.reset()
        let inputFolderURL = URL(fileURLWithPath: inputFolderName, isDirectory: true)
        let configuration = makeConfigurations()
        logger.log("Using configuration: \(String(describing: configuration))")
        
        var maybeSession: PhotogrammetrySession? = nil
        do {
            maybeSession = try PhotogrammetrySession(input: inputFolderURL, configuration: configuration)
            self.isSessionReady = true
            logger.log("Successfully created session")
        } catch {
            self.isSessionReady = false
            logger.error("Error creating session: (\(String(describing: error))")
        }
        
        guard let session = maybeSession else {
            self.isSessionReady = false
            return
        }
        
        let waiter = Task {
            do {
                for try await output in session.outputs {
                    switch output {
                    case .processingComplete:
                        logger.log("Processing is complete!")
                        self.isProcessingFinished = true
                        return
                    case .requestError(let request, let error):
                        logger.error("Request \(String(describing: request)) had an error: \(String(describing: error))")
                    case .requestComplete(let request, let result):
                        PhotogrammetryViewModel.handleRequestComplete(request: request, result: result)
                    case .requestProgress(let request, let fractionComplete):
                        PhotogrammetryViewModel.handleRequestProgress(request: request, fractionComplete: fractionComplete)
                        
                    case .inputComplete:
                        logger.log("Data ingestion is complete. Beginning processing...")
                    case .invalidSample(let id, let reason):
                        logger.warning("Invalid Sample! id=\(id) reason=\"\(reason)\"")
                    case .skippedSample(let id):
                        logger.warning("Sample id=\(id) was skipped by processing")
                    case .automaticDownsampling:
                        logger.warning("Automatic downsampling was applied!")
                    case .processingCancelled:
                        logger.warning("Processing was canceled")
                    @unknown default:
                        logger.error("Output: unhandled message: \(output.localizedDescription)")
                    }
                }
            } catch {
                logger.error("Output: ERROR = \(String(describing: error))")
                self.isProcessingFinished = true
                return
            }
        }
        
        // The compiler may deinitialize these objects since they may appear to be
        // unused. This keeps them from being deallocated until they exit.
        withExtendedLifetime((session, waiter)) {
            // Run the main process call on the request, then enter the main run
            // loop until you get the published completion event or error.
            do {
                let request = makeRequests()
                logger.log("Using request: \(String(describing: request))")
                try session.process(requests: [ request ])
                // Enter the infinite loop dispatcher used to process asynchronous
                // blocks on the main queue. You explicitly exit above to stop the loop.
                RunLoop.main.run()
            } catch {
                logger.critical("Process got error: \(String(describing: error))")
                Foundation.exit(1)
            }
        }
    }
    
    // MARK: Private functions
    
    private func updatePhotogrammetryDetail(_ detail: String) {
        do {
            self.detail = try PhotogrammetrySession.Request.Detail(detail)
            logger.log("Photogrammetry.Request.Detail set to \(detail)")
        } catch {
            logger.error("Unable to set Photogrammetry.Request.Detail \(error)")
        }
    }
    
    private func updatePhotogrammetrySampleOrdering(_ sampleOrdering: String) {
        do {
            self.sampleOrdering = try PhotogrammetrySession.Configuration.SampleOrdering(sampleOrdering: sampleOrdering)
            logger.log("Photogrammetry.Configuration.SampleOrdering set to \(sampleOrdering)")
        } catch {
            logger.error("Unable to set Photogrammetry.Configuration.SampleOrdering \(error)")
        }
    }
    
    private func updatePhotogrammetryFeatureSensitivity(_ featureSensitivity: String) {
        do {
            self.featureSensitivity = try PhotogrammetrySession.Configuration.FeatureSensitivity(featureSensitivity: featureSensitivity)
            logger.log("Photogrammetry.Configuration.FeatureSensitivity set to \(featureSensitivity)")
        } catch {
            logger.error("Unable to set Photogrammetry.Configuration.FeatureSensitivity \(error)")
        }
    }
    
    private func reset() {
        self.isProcessingFinished = false
        self.isSessionReady = false
        PhotogrammetryViewModel.shared.requestProgress = 0.0
    }
    
    private func makeConfigurations() -> PhotogrammetrySession.Configuration {
        var configuration = PhotogrammetrySession.Configuration()
        sampleOrdering.map { configuration.sampleOrdering = $0 }
        featureSensitivity.map { configuration.featureSensitivity = $0 }
        return configuration
    }
    
    private func makeRequests() -> PhotogrammetrySession.Request {
        let outputURL = URL(fileURLWithPath: outputFileName)
        if let detailSetting = detail {
            return PhotogrammetrySession.Request.modelFile(url: outputURL, detail: detailSetting)
        } else {
            return PhotogrammetrySession.Request.modelFile(url: outputURL)
        }
    }
    
    private static func handleRequestComplete(request: PhotogrammetrySession.Request, result: PhotogrammetrySession.Result) {
        logger.log("Request complete: \(String(describing: request)) with result ... ")
        
        switch result {
        case .modelFile(let url):
            logger.log("\tmodelFile available at url=\(url)")
        default:
            logger.warning("\tUnexpected result: \(String(describing: result))")
        }
    }
    
    private static func handleRequestProgress(request: PhotogrammetrySession.Request, fractionComplete: Double) {
        logger.log("Progress(request = \(String(describing: request)) = \(fractionComplete)")
        PhotogrammetryViewModel.shared.requestProgress = fractionComplete
    }
}

private enum IllegalOption: Swift.Error {
    case invalidDetail(String)
    case invalidSampleOverlap(String)
    case invalidSampleOrdering(String)
    case invalidFeatureSensitivity(String)
}

@available(macOS 12.0, *)
extension PhotogrammetrySession.Request.Detail {
    init(_ detail: String) throws {
        switch detail {
        case "preview": self = .preview
        case "reduced": self = .reduced
        case "medium" : self = .medium
        case "full": self = .full
        case "raw": self = .raw
        default: throw IllegalOption.invalidDetail(detail)
        }
    }
}


@available(macOS 12.0, *)
extension PhotogrammetrySession.Configuration.SampleOrdering {
    init(sampleOrdering: String) throws {
        switch sampleOrdering {
        case "unordered": self = .unordered
        case "sequential": self = .sequential
        default: throw IllegalOption.invalidSampleOrdering(sampleOrdering)
        }
        
    }
    
}

@available(macOS 12.0, *)
extension PhotogrammetrySession.Configuration.FeatureSensitivity {
    init(featureSensitivity: String) throws {
        switch featureSensitivity {
        case "normal": self = .normal
        case "high": self = .high
        default: throw IllegalOption.invalidFeatureSensitivity(featureSensitivity)
        }
    }
}

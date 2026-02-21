import Foundation
import CoreML
import Vision
#if canImport(UIKit)
import UIKit
#endif

/// Handles object detection using Vision framework's built-in detectors.
/// All processing happens locally on the Neural Engine — 100% offline.
@available(macOS 11.0, *)
@available(iOS 16.0, *)
class CoreMLHandler: ObservableObject {
    @Published var detectedRectangles: [VNRectangleObservation] = []
    @Published var detectedContours: [VNContoursObservation] = []
    
    init() {
        // No model needed — uses Vision's built-in detectors
    }
    
    // MARK: - Rectangle Detection (for mechanical parts, panels, etc.)
    func detectRectangles(in pixelBuffer: CVPixelBuffer, completion: @escaping ([VNRectangleObservation]) -> Void) {
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                print("[Kineprint] Rectangle detection error: \(error.localizedDescription)")
                completion([])
                return
            }
            guard let results = request.results as? [VNRectangleObservation] else {
                completion([])
                return
            }
            completion(results)
        }
        
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.1
        request.maximumObservations = 10
        request.minimumConfidence = 0.5
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("[Kineprint] Rectangle detection failed: \(error.localizedDescription)")
            completion([])
        }
    }
    
    // MARK: - Contour Detection (for edges/outlines of mechanical objects)
    func detectContours(in pixelBuffer: CVPixelBuffer, completion: @escaping ([VNContoursObservation]) -> Void) {
        let request = VNDetectContoursRequest { request, error in
            if let error = error {
                print("[Kineprint] Contour detection error: \(error.localizedDescription)")
                completion([])
                return
            }
            guard let results = request.results as? [VNContoursObservation] else {
                completion([])
                return
            }
            completion(results)
        }
        
        request.contrastAdjustment = 2.0
        request.maximumImageDimension = 512
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("[Kineprint] Contour detection failed: \(error.localizedDescription)")
            completion([])
        }
    }
    
    // MARK: - Object Classification
    func classifyObject(in pixelBuffer: CVPixelBuffer, completion: @escaping (String, String) -> Void) {
        let request = VNClassifyImageRequest { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                completion("Unknown Object", "Organic-Synthetic Hybrid")
                return
            }
            
            let label = topResult.identifier.replacingOccurrences(of: "_", with: " ").capitalized
            _ = topResult.confidence
            
            // Heuristic for material based on classification
            var material = "Composite Material"
            let labelLower = label.lowercased()
            if labelLower.contains("metal") || labelLower.contains("tool") || labelLower.contains("car") || labelLower.contains("machine") {
                material = "High-Grade Alloy"
            } else if labelLower.contains("plastic") || labelLower.contains("bottle") || labelLower.contains("toy") {
                material = "Advanced Polymer"
            } else if labelLower.contains("cloth") || labelLower.contains("shirt") || labelLower.contains("fabric") {
                material = "Synthetic Fiber"
            } else if labelLower.contains("wood") || labelLower.contains("table") || labelLower.contains("chair") {
                material = "Processed Cellulose"
            } else if labelLower.contains("glass") || labelLower.contains("window") || labelLower.contains("lens") {
                material = "Silicate Matrix"
            } else if labelLower.contains("person") || labelLower.contains("human") || labelLower.contains("face") {
                material = "Biological Tissue"
            }
            
            completion(label, material)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion("Unknown Object", "Organic-Synthetic Hybrid")
        }
    }
    
    // MARK: - Human Detection
    func detectHumans(in pixelBuffer: CVPixelBuffer, completion: @escaping ([VNHumanObservation]) -> Void) {
        let request = VNDetectHumanRectanglesRequest { request, error in
            guard let results = request.results as? [VNHumanObservation] else {
                completion([])
                return
            }
            completion(results)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
        } catch {
            completion([])
        }
    }
    
    // MARK: - Process AR Frame (called per-frame from KineprintARView)
    func processFrame(pixelBuffer: CVPixelBuffer) -> ([VNRectangleObservation], [VNHumanObservation]) {
        var rects: [VNRectangleObservation] = []
        var humans: [VNHumanObservation] = []
        
        let rectRequest = VNDetectRectanglesRequest()
        rectRequest.minimumConfidence = 0.6
        
        let humanRequest = VNDetectHumanRectanglesRequest()
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([rectRequest, humanRequest])
            rects = (rectRequest.results) ?? []
            humans = (humanRequest.results) ?? []
        } catch { }
        
        return (rects, humans)
    }
}

#if canImport(UIKit)
// Extension to convert CVPixelBuffer to UIImage if needed
extension CVPixelBuffer {
    private static let context = CIContext(options: nil)
    
    @discardableResult
    func toUIImage() -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: self)
        let context = CVPixelBuffer.context
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
#endif

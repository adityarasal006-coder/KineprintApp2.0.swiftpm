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
    
    // MARK: - Process AR Frame (called per-frame from KineprintARView)
    func processFrame(pixelBuffer: CVPixelBuffer) -> [VNRectangleObservation] {
        var results: [VNRectangleObservation] = []
        
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.1
        request.maximumObservations = 5
        request.minimumConfidence = 0.5
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([request])
            if let observations = request.results {
                results = observations
            }
        } catch {
            // Silently fail — frame processing is best-effort
        }
        
        return results
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

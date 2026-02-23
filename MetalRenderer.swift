import Metal
import MetalKit
import simd

/// Metal renderer for potential future use.
/// Currently, neon glow effects are handled by SceneKit's bloom technique
/// in KineprintARView, which integrates directly with the AR pipeline.
class MetalRenderer {
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    
    init() {
        setupMetal()
    }
    
    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("[Kineprint] Metal is not supported on this device")
            return
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
    }
    
    var isAvailable: Bool {
        return device != nil
    }
}
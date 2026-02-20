#if os(iOS)
import Foundation
import SwiftUI
import simd

@available(iOS 16.0, *)
@MainActor
class SimulatorMock {
    static let shared = SimulatorMock()
    private var timer: Timer?
    private var time: Float = 0
    weak var viewModel: KineprintViewModel?
    
    func startMocking(for viewModel: KineprintViewModel) {
        self.viewModel = viewModel
        viewModel.startTrackingObject(at: SIMD3<Float>(0, 0, -1))
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMock()
            }
        }
    }
    
    func stopMocking() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMock() {
        guard let vm = viewModel, vm.trackingActive else { return }
        
        time += 0.1
        
        // Simulate a circular motion with varying speed
        let radius: Float = 0.5
        let speedMultiplier: Float = 1.0 + (sin(time * 0.5) * 0.5) // Speed varies over time
        
        let position = SIMD3<Float>(
            sin(time * speedMultiplier) * radius,
            (sin(time * 2.0) * 0.2) + 0.5, // gentle bobbing
            -1.0 + (cos(time * speedMultiplier) * radius)
        )
        
        // Calculate rough derivatives
        let velocity = SIMD3<Float>(
            cos(time * speedMultiplier) * speedMultiplier * radius,
            cos(time * 2.0) * 0.4,
            -sin(time * speedMultiplier) * speedMultiplier * radius
        )
        
        let acceleration = SIMD3<Float>(
            -sin(time * speedMultiplier) * speedMultiplier * speedMultiplier * radius,
            -sin(time * 2.0) * 0.8,
            -cos(time * speedMultiplier) * speedMultiplier * speedMultiplier * radius
        )
        
        vm.updateTrackedObject(position: position, velocity: velocity, acceleration: acceleration)
    }
}
#endif

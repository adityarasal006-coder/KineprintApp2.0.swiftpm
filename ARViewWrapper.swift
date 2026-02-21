#if os(iOS)
import SwiftUI
import ARKit
import SceneKit
import UIKit
import AVFoundation

/// Bridges SwiftUI with the custom KineprintARView.
/// Handles tap-to-track: user taps a surface to place a tracking anchor.
@available(iOS 16.0, *)
@MainActor
final class KineprintARViewWrapper: UIView {
    private var kineprintARView: KineprintARView?
    var viewModel: KineprintViewModel?
    private var activeObjectId: UUID?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Only create AR views if ARKit is actually supported (not on simulator)
        guard ARWorldTrackingConfiguration.isSupported else {
            setupPlaceholder()
            return
        }
        
        let arView = KineprintARView(frame: bounds)
        arView.translatesAutoresizingMaskIntoConstraints = false
        arView.onTrackingUpdate = { [weak self] position, velocity, acceleration in
            self?.handleTrackingUpdate(position: position, velocity: velocity, acceleration: acceleration)
        }
        
        addSubview(arView)
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: topAnchor),
            arView.bottomAnchor.constraint(equalTo: bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        kineprintARView = arView
        
        // Tap to place tracking anchor
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    private func setupPlaceholder() {
        backgroundColor = .black
        
        let label = UILabel()
        label.text = "AR NOT AVAILABLE\nRequires physical device\n\nSimulator Mock Mode active."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor(red: 0, green: 1, blue: 0.85, alpha: 0.6)
        label.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // Call this if not on a physical device, so they can test features
    func startSimulatorMock() {
        guard let vm = viewModel else { return }
        SimulatorMock.shared.startMocking(for: vm)
    }
    
    func startARSession() {
        kineprintARView?.startARSession()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = kineprintARView else { return }
        let location = gesture.location(in: self)
        
        // Raycast against detected planes for accurate placement
        guard let query = arView.arSCNView.raycastQuery(
            from: location,
            allowing: .estimatedPlane,
            alignment: .any
        ) else { return }
        
        let results = arView.arSession.raycast(query)
        guard let firstResult = results.first else { return }
        
        let position = SIMD3<Float>(
            firstResult.worldTransform.columns.3.x,
            firstResult.worldTransform.columns.3.y,
            firstResult.worldTransform.columns.3.z
        )
        
        // Place a tracked object at the tapped position
        activeObjectId = arView.addTrackedObject(at: position)
        viewModel?.startTrackingObject(at: position)
    }
    
    private func handleTrackingUpdate(position: SIMD3<Float>, velocity: SIMD3<Float>, acceleration: SIMD3<Float>) {
        viewModel?.updateTrackedObject(position: position, velocity: velocity, acceleration: acceleration)
    }
    
    func updateShowVectors(_ show: Bool) {
        kineprintARView?.showVectors = show
    }
    
    func updateRecordingPath(_ recording: Bool) {
        kineprintARView?.recordingPath = recording
    }
}

@available(iOS 16.0, *)
struct ARCameraView: View {
    @ObservedObject var viewModel: KineprintViewModel
    
    var body: some View {
                    Text("CAMERA ACCESS REQUIRED")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("Kineprint needs camera access to perform deep analysis of your physical environment.")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Grant Access in Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(red: 0, green: 1, blue: 0.85))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.0, green: 0.05, blue: 0.1)) // Deep dark blue
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraAuthorized = true
            hasRequested = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraAuthorized = granted
                    self.hasRequested = true
                }
            }
        case .denied, .restricted:
            cameraAuthorized = false
            hasRequested = true
        @unknown default:
            cameraAuthorized = false
            hasRequested = true
        }
    }
}

@available(iOS 16.0, *)
struct ARCameraViewController: UIViewRepresentable {
    @ObservedObject var viewModel: KineprintViewModel
    
    func makeUIView(context: Context) -> KineprintARViewWrapper {
        let arView = KineprintARViewWrapper(frame: .zero)
        arView.viewModel = viewModel
        if ARWorldTrackingConfiguration.isSupported {
            arView.startARSession()
        } else {
            arView.startSimulatorMock()
        }
        context.coordinator.wrapper = arView
        return arView
    }
    
    func updateUIView(_ uiView: KineprintARViewWrapper, context: Context) {
        uiView.updateShowVectors(viewModel.showVectors)
        uiView.updateRecordingPath(viewModel.recordingPath)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        weak var wrapper: KineprintARViewWrapper?
    }
}
#endif

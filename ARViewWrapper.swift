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
            DispatchQueue.main.async {
                self?.handleTrackingUpdate(position: position, velocity: velocity, acceleration: acceleration)
            }
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
    
    func takeSnapshot() -> UIImage? {
        return kineprintARView?.arSCNView.snapshot()
    }
}

@available(iOS 16.0, *)
struct ARCameraView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var cameraAuthorized = false
    @State private var hasRequested = false
    
    var body: some View {
        ZStack {
            if cameraAuthorized {
                ARCameraViewController(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                
                LiveTargetReticleOverlay(viewModel: viewModel)
            } else if hasRequested {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill.badge.ellipsis")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.85))
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
        
        // Pass snapshot closure to ViewModel
        viewModel.onCaptureBlueprint = { [weak arView] in
            return arView?.takeSnapshot()
        }
        
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

@available(iOS 16.0, *)
struct LiveTargetReticleOverlay: View {
    @ObservedObject var viewModel: KineprintViewModel
    
    @State private var rotatingAngle: Double = 0
    @State private var scanLineOffset: CGFloat = -125
    @State private var timer: Timer?
    @State private var liveAngleX: Int = 0
    @State private var liveAngleY: Int = 0
    @State private var liveDepth: Double = 0.0
    @State private var liveTexture: String = "ANALYZING..."
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        ZStack {
            // Central Reticle - ENLARGED AND CENTERED
            ZStack {
                Circle()
                    .stroke(neonCyan.opacity(0.4), lineWidth: 1)
                    .frame(width: 320, height: 320)
                
                Circle()
                    .stroke(neonCyan.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [10, 20]))
                    .frame(width: 300, height: 300)
                    .rotationEffect(.degrees(rotatingAngle))
                
                Path { p in
                    p.move(to: CGPoint(x: 160, y: 15))
                    p.addLine(to: CGPoint(x: 160, y: 55))
                    
                    p.move(to: CGPoint(x: 160, y: 265))
                    p.addLine(to: CGPoint(x: 160, y: 305))
                    
                    p.move(to: CGPoint(x: 15, y: 160))
                    p.addLine(to: CGPoint(x: 55, y: 160))
                    
                    p.move(to: CGPoint(x: 265, y: 160))
                    p.addLine(to: CGPoint(x: 305, y: 160))
                }
                .stroke(neonCyan, lineWidth: 2)
                .frame(width: 320, height: 320)
                
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, neonCyan.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: 320, height: 3)
                    .offset(y: scanLineOffset * 1.28)
            }
            // Removed bottom padding to keep it centered
            
            // HUD Text Panels - UPGRADED WITH BIO/ENVIRONMENTAL DATA
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("QUANTUM TARGET LOCK")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        Text("∠X: \(liveAngleX)° | ∠Y: \(liveAngleY)°")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                        Text(String(format: "DEPTH_MTR: %.3fm", liveDepth))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                        Text("BIO_THERM: 36.6°C")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(10)
                    .frame(width: 170, alignment: .leading)
                    .background(Color.black.opacity(0.6))
                    .border(neonCyan.opacity(0.6), width: 1)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("SPATIAL_ANALYTICS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        Text(liveTexture)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                        Text("VIB_FREQ: 142.4 Hz")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.orange)
                        Text("MASS_EST: 64.2kg")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(neonCyan.opacity(0.8))
                    }
                    .padding(10)
                    .frame(width: 170, alignment: .trailing)
                    .background(Color.black.opacity(0.6))
                    .border(neonCyan.opacity(0.6), width: 1)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 85) // Moved lower to avoid reticle overlap
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotatingAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scanLineOffset = 125
            }
            
            let textures = ["METALLIC_ALLOY", "CARBON_POLYMER", "SILICATE_MATRIX", "SYNTHETIC_FIBER", "BIO_CELLULAR", "COMPOSITE_GEN-4"]
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                liveAngleX = Int.random(in: -45...45)
                liveAngleY = Int.random(in: -45...45)
                liveDepth = Double.random(in: 0.3...3.5)
                if Int.random(in: 0...4) == 0 {
                    liveTexture = textures.randomElement() ?? "SCANNING..."
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}
#endif

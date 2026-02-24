import SwiftUI
import AVFoundation
import UIKit
import PhotosUI

struct ScientificCalculatorView: View {
    @State private var display = "0"
    @State private var history = ""
    @State private var showScanner = false
    @State private var scannedSteps: [String] = []
    @State private var showSteps = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    let buttons: [[String]] = [
        ["sin", "cos", "tan", "log"],
        ["ln", "√", "π", "e"],
        ["AC", "⌫", "%", "/"],
        ["7", "8", "9", "*"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["0", ".", "=", "^"]
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan).opacity(0.15)
            
            VStack(spacing: 0) {
                // ═══ Header Bar ═══
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(neonCyan).frame(width: 6, height: 6)
                            .shadow(color: neonCyan, radius: 4)
                        Text("COMPUTATION_NODE")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    Spacer()
                    Button(action: { showScanner = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.viewfinder")
                            Text("OPTICAL MATRIX SCAN")
                        }
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(neonCyan)
                        .cornerRadius(10)
                        .shadow(color: neonCyan.opacity(0.6), radius: 8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(Color.black.opacity(0.5))
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(neonCyan.opacity(0.2)), alignment: .bottom
                )
                
                Spacer()
                
                // ═══ Display Area ═══
                VStack(alignment: .trailing, spacing: 10) {
                    if !scannedSteps.isEmpty {
                        Button(action: { withAnimation { showSteps.toggle() } }) {
                            HStack(spacing: 4) {
                                Image(systemName: showSteps ? "chevron.up" : "list.bullet")
                                    .font(.system(size: 10))
                                Text(showSteps ? "HIDE_STEPS" : "SHOW_STEPS")
                            }
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    
                    if showSteps, !scannedSteps.isEmpty {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(0..<scannedSteps.count, id: \.self) { i in
                                    Text("STEP \(i+1): \(scannedSteps[i])")
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(neonCyan)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    } else {
                        Text(history)
                            .font(.system(size: 20, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(display)
                            .font(.system(size: 56, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                            .shadow(color: neonCyan.opacity(0.3), radius: 8)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(height: showSteps ? 200 : nil)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(neonCyan.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Spacer().frame(height: 20)
                
                // ═══ Keypad ═══
                VStack(spacing: 12) {
                    ForEach(buttons, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(row, id: \.self) { btn in
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    self.buttonTapped(btn)
                                }) {
                                    Text(btn)
                                        .font(.system(size: btn.count > 1 ? 18 : 26, weight: .medium, design: .monospaced))
                                        .frame(maxWidth: .infinity, maxHeight: 58)
                                        .foregroundColor(self.buttonColor(btn))
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(self.buttonColor(btn).opacity(0.2), lineWidth: 1)
                                        )
                                        .shadow(color: self.buttonColor(btn).opacity(0.08), radius: 4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScannerHackingOverlay(onComplete: { steps, result, problem in
                display = result
                history = "SCANNED: " + problem
                scannedSteps = steps
                showScanner = false
            })
        }
    }
    
    private func buttonColor(_ btn: String) -> Color {
        if ["AC", "⌫"].contains(btn) { return .red }
        if ["/", "*", "-", "+", "="].contains(btn) { return Color.orange }
        if ["sin", "cos", "tan", "log", "ln", "√", "π", "e", "%", "^"].contains(btn) { return neonCyan.opacity(0.8) }
        return .white
    }
    
    private func buttonTapped(_ btn: String) {
        switch btn {
        case "AC":
            display = "0"; history = ""; scannedSteps = []; showSteps = false
        case "⌫":
            if display.count > 1 { display.removeLast() } else { display = "0" }
        case "=":
            history = display + " ="
            display = calculateResult(display)
            scannedSteps = []
            showSteps = false
        case "π":
            if display == "0" { display = "3.14159" } else { display += "3.14159" }
        case "e":
            if display == "0" { display = "2.71828" } else { display += "2.71828" }
        default:
            if display == "0" && !["/", "*", "-", "+", ".", "%", "^"].contains(btn) { display = btn }
            else { display += btn }
        }
    }
    
    private func calculateResult(_ expression: String) -> String {
        let expr = expression.replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/")
        let exp = NSExpression(format: expr)
        if let result = exp.expressionValue(with: nil, context: nil) as? NSNumber { return result.stringValue }
        return "ERROR"
    }
}

// MARK: - Scanner Hacking Drone Scene
struct ScannerHackingOverlay: View {
    var onComplete: ([String], String, String) -> Void
    @State private var scanPhase = 0
    @State private var matrixLines: [String] = Array(repeating: "", count: 40)
    @State private var glitchOffset: CGFloat = 0
    @State private var showRedWarning = false
    @State private var isScanning = false
    @State private var laserScanOffset: CGFloat = -150
    @State private var innerRotation: Double = 0
    @State private var middleRotation: Double = 0
    @State private var outerRotation: Double = 0
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Live Camera Background
            LiveCameraPreview()
                .ignoresSafeArea()
                .opacity(0.85)
                .colorMultiply(isScanning ? (showRedWarning ? .red : neonCyan) : .white)
                .blur(radius: isScanning ? (scanPhase > 2 ? 0 : 2) : 0)
                .animation(.easeInOut, value: showRedWarning)
                .animation(.easeInOut, value: isScanning)
            
            // Matrix Background Hack
            if isScanning {
                GeometryReader { geo in
                    ForEach(0..<20, id: \.self) { i in
                        Text(matrixLines[i])
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(showRedWarning ? .red : neonCyan.opacity(0.6))
                            .position(x: CGFloat.random(in: 0...geo.size.width),
                                      y: CGFloat(i) * (geo.size.height / 20))
                            .animation(.linear(duration: 0.1), value: matrixLines)
                    }
                }
                .blur(radius: scanPhase > 2 ? 0 : 2)
            }
            
            // Futuristic Camera Reticle & HUD
            GeometryReader { geo in
                VStack {
                    Spacer()
                    ZStack {
                        // Tactical Corner Brackets
                        Group {
                            // Top Left
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 30))
                                path.addLine(to: CGPoint(x: 0, y: 0))
                                path.addLine(to: CGPoint(x: 30, y: 0))
                            }.stroke(showRedWarning ? Color.red : neonCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .miter))
                            .frame(width: 320, height: 180, alignment: .topLeading)
                            
                            // Top Right
                            Path { path in
                                path.move(to: CGPoint(x: 290, y: 0))
                                path.addLine(to: CGPoint(x: 320, y: 0))
                                path.addLine(to: CGPoint(x: 320, y: 30))
                            }.stroke(showRedWarning ? Color.red : neonCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .miter))
                            .frame(width: 320, height: 180, alignment: .topTrailing)
                            
                            // Bottom Left
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 150))
                                path.addLine(to: CGPoint(x: 0, y: 180))
                                path.addLine(to: CGPoint(x: 30, y: 180))
                            }.stroke(showRedWarning ? Color.red : neonCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .miter))
                            .frame(width: 320, height: 180, alignment: .bottomLeading)
                            
                            // Bottom Right
                            Path { path in
                                path.move(to: CGPoint(x: 320, y: 150))
                                path.addLine(to: CGPoint(x: 320, y: 180))
                                path.addLine(to: CGPoint(x: 290, y: 180))
                            }.stroke(showRedWarning ? Color.red : neonCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .miter))
                            .frame(width: 320, height: 180, alignment: .bottomTrailing)
                        }
                        .frame(width: 320, height: 180)
                        .scaleEffect(isScanning ? (scanPhase == 1 ? 0.95 : 1.0) : 1.05)
                        .rotationEffect(.degrees(showRedWarning && glitchOffset > 0 ? 1 : 0))
                        
                        // Iron Man / JARVIS Style ARC Reactor HUD
                        if isScanning {
                            // Radar Sweeper
                            ZStack {
                                Circle()
                                    .fill(
                                        AngularGradient(gradient: Gradient(colors: [.clear, showRedWarning ? .red.opacity(0.8) : neonCyan.opacity(0.5)]), center: .center)
                                    )
                                    .frame(width: 280, height: 280)
                                    .rotationEffect(.degrees(outerRotation))
                                
                                // Outer Data Ring
                                Circle()
                                    .stroke(showRedWarning ? Color.red : neonCyan, style: StrokeStyle(lineWidth: 1, dash: [4, 8]))
                                    .frame(width: 260, height: 260)
                                    .rotationEffect(.degrees(-outerRotation))
                                
                                // Middle Thick segmented Ring
                                Circle()
                                    .stroke(showRedWarning ? Color.red : neonCyan, style: StrokeStyle(lineWidth: 6, dash: [30, 15, 5, 15]))
                                    .frame(width: 200, height: 200)
                                    .rotationEffect(.degrees(middleRotation))
                                
                                // Inner Fast Ring
                                Circle()
                                    .stroke(showRedWarning ? Color.red : neonCyan, style: StrokeStyle(lineWidth: 2, dash: [10, 10]))
                                    .frame(width: 140, height: 140)
                                    .rotationEffect(.degrees(innerRotation))
                                
                                // Central Crosshairs
                                Rectangle().fill(showRedWarning ? Color.red : neonCyan).frame(width: 1, height: 40)
                                Rectangle().fill(showRedWarning ? Color.red : neonCyan).frame(width: 40, height: 1)
                                Circle().stroke(showRedWarning ? Color.red : neonCyan, lineWidth: 2).frame(width: 20, height: 20)
                            }
                            .offset(x: glitchOffset)
                            
                            // Massive Data Streams (Left Side)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SYS.LOCK: \(matrixLines[0].prefix(8))")
                                Text("LATENCY: \(Int.random(in: 10...20))ms")
                                Text(showRedWarning ? "OVR: WARNING" : "OVR: STABLE")
                                Text("THR: \(Int.random(in: 80...99))%")
                                Text("MEM: 0x\(matrixLines[1].prefix(4))")
                                ForEach(2..<8, id: \.self) { i in
                                    Text(matrixLines[i].prefix(6))
                                        .opacity(0.5)
                                }
                            }
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(showRedWarning ? .red : neonCyan.opacity(0.8))
                            .position(x: 30, y: 0)
                            
                            // Massive Data Streams (Right Side)
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("TARGET_AQUIRED")
                                Text("M-MATRIX: \(matrixLines[8].prefix(5))")
                                Text(showRedWarning ? "V-STREAM: MAX" : "V-STREAM: NOMINAL")
                                Text("CALC_LOAD: \(Int.random(in: 60...85))%")
                                ForEach(9..<15, id: \.self) { i in
                                    Text(matrixLines[i].prefix(8))
                                        .opacity(0.5)
                                }
                            }
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(showRedWarning ? .red : neonCyan.opacity(0.8))
                            .position(x: 290, y: 0)
                        }
                        
                        // Central Status Text
                        VStack(spacing: 8) {
                            if !isScanning {
                                Text("CALIBRATE OPTICAL SENSOR")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonCyan)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                            } else {
                                if scanPhase == 0 {
                                    Text("ACQUIRING NEURAL LOCK...")
                                        .font(.system(size: 18, weight: .black, design: .monospaced))
                                        .foregroundColor(neonCyan)
                                        .background(Color.black.opacity(0.5))
                                } else if scanPhase == 1 {
                                    Text("DECRYPTING ALGORITHMS...")
                                        .font(.system(size: 16, weight: .black, design: .monospaced))
                                        .foregroundColor(.orange)
                                        .background(Color.black.opacity(0.5))
                                } else if scanPhase == 2 {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text("CRITICAL: BYPASSING ENCRYPTION")
                                    }
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(.red)
                                    .background(Color.black.opacity(0.5))
                                } else {
                                    Text("SYSTEM SOLVED")
                                        .font(.system(size: 32, weight: .black, design: .monospaced))
                                        .foregroundColor(.green)
                                        .shadow(color: .green, radius: 20)
                                        .background(Color.black.opacity(0.5))
                                }
                            }
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width, height: 300)
                    Spacer()
                    
                    if !isScanning {
                        Button(action: startScan) {
                            HStack(spacing: 12) {
                                Image(systemName: "viewfinder.circle.fill")
                                    .font(.system(size: 28))
                                Text("INITIALIZE DEEP SCAN")
                            }
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(neonCyan)
                            .cornerRadius(12)
                            .shadow(color: neonCyan.opacity(0.8), radius: 15)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 1)
                                    .padding(.horizontal, 40)
                                    .padding(.bottom, 60)
                            )
                        }
                    }
                }
            }
            
            if scanPhase > 0 {
                Color.black.opacity(scanPhase == 1 ? 0.3 : 0.0)
                    .colorInvert()
                    .opacity(showRedWarning ? 0.2 : 0)
                    .ignoresSafeArea()
            }
        }
        .onReceive(timer) { _ in
            for i in 0..<20 {
                let randomBits = (0..<15).map { _ in ["0", "1", "A", "X", "F", "λ", "∫", "∑", "∆"].randomElement()! }.joined()
                matrixLines[i] = randomBits
            }
            if isScanning && scanPhase >= 1 {
                glitchOffset = CGFloat.random(in: -10...10)
                if Int.random(in: 0...4) == 0 {
                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                    generator.impactOccurred()
                }
            }
        }
    }
    
    private func startScan() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isScanning = true }
        
        // Start Iron Man Ring Rotations
        withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
            innerRotation = 360
        }
        withAnimation(Animation.linear(duration: 6).repeatForever(autoreverses: false)) {
            middleRotation = -360
        }
        withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
            outerRotation = 360
        }
        
        AudioServicesPlaySystemSound(1306) // Deep tech click start
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { scanPhase = 1 }
            AudioServicesPlaySystemSound(1053) // Sharp lock click
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showRedWarning = true
            withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) { scanPhase = 2 }
            AudioServicesPlaySystemSound(1322) // Alarming horror system alert
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            showRedWarning = false
            withAnimation { scanPhase = 3; glitchOffset = 0 }
            AudioServicesPlaySystemSound(1307) // Confirmation lock
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Demo Solved Problem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete([
                    "∫ (3x² + 2x) dx",
                    "= 3∫x²dx + 2∫xdx",
                    "= 3(x³/3) + 2(x²/2)",
                    "= x³ + x² + C",
                    "Compute bounded [0, 2]:",
                    "= (2³ + 2²) - (0 + 0)",
                    "= 8 + 4 = 12"
                ], "12", "∫[0→2](3x²+2x)dx")
            }
        }
    }
}

// MARK: - Live Camera Preview Layer
struct LiveCameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return view
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

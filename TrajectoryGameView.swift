#if os(iOS)
import SwiftUI

// MARK: - Match Trajectory Game

@MainActor
@available(iOS 16.0, *)
struct TrajectoryGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonGreen = Color(red: 0.2, green: 1, blue: 0.4)
    private let neonOrange = Color(red: 1, green: 0.6, blue: 0.1)
    
    @State private var userPath: [CGPoint] = []
    @State private var isDrawing = false
    @State private var accuracy: Double = 0.0
    @State private var showResult = false
    @State private var level = 1
    @State private var showHint = false
    @State private var streak = 0
    @State private var totalScore = 0
    @State private var canvasSize: CGSize = .zero
    @State private var thinkingLog: [String] = ["SYSTEM_INIT: READY", "AWAITING_KINEMATIC_INPUT"]
    
    // Physics parameters for the current level
    private var physicsParams: (v0: Double, angle: Double) {
        let v0 = 15.0 + Double(level) * 3.0
        let angle = Double.pi / 4.0 // 45 degrees for classic parabola
        return (v0, angle)
    }
    
    // Target points calculated to fit the canvas perfectly
    private var targetPoints: [CGPoint] {
        guard canvasSize.width > 0 && canvasSize.height > 0 else { return [] }
        let g = 9.81
        let (v0, angle) = physicsParams
        
        let flightTime = 2.0 * v0 * sin(angle) / g
        let range = v0 * v0 * sin(2.0 * angle) / g
        let maxHeight = v0 * v0 * pow(sin(angle), 2) / (2 * g)
        
        // Dynamic scaling to fill ~80% of canvas
        let scaleX = (canvasSize.width * 0.85) / range
        let scaleY = (canvasSize.height * 0.70) / maxHeight
        let offsetX = canvasSize.width * 0.07 // Left margin
        let offsetY = canvasSize.height * 0.15 // Bottom margin
        
        var pts: [CGPoint] = []
        for i in stride(from: 0.0, through: flightTime, by: flightTime / 40.0) {
            let t = i
            let x = v0 * cos(angle) * t
            let y = v0 * sin(angle) * t - 0.5 * g * t * t
            
            let screenX = offsetX + x * scaleX
            let screenY = canvasSize.height - offsetY - y * scaleY
            pts.append(CGPoint(x: screenX, y: screenY))
        }
        return pts
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scientist HUD Header
                GameHeader(
                    title: "TRAJECTORY_CALIBRATION",
                    icon: "target",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { showHint.toggle() }
                )
                
                // Advanced Scientific Layout
                ZStack {
                    // Grid background
                    GeometryReader { geo in
                        GridBackground(color: neonCyan, size: geo.size)
                            .onAppear { canvasSize = geo.size }
                            .onChange(of: geo.size) { newSize in canvasSize = newSize }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Data Stream Overlay
                        ScientificHUDOverlay(level: level, params: physicsParams, logs: thinkingLog)
                            .padding(16)
                        
                        Spacer()
                        
                        // Interaction Area
                        ZStack {
                            // Axis Labels
                            VStack {
                                Spacer()
                                HStack {
                                    Text("0.00m (ORIGIN)")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(neonCyan.opacity(0.4))
                                        .padding(.leading, 10)
                                    Spacer()
                                    Text("R: \(String(format: "%.2f", physicsParams.v0 * physicsParams.v0 * sin(2.0 * physicsParams.angle) / 9.81))m")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(neonCyan.opacity(0.4))
                                        .padding(.trailing, 10)
                                }
                            }
                            
                            // Target path (blueprint style)
                            if !targetPoints.isEmpty {
                                Path { path in
                                    path.move(to: targetPoints[0])
                                    for pt in targetPoints.dropFirst() { path.addLine(to: pt) }
                                }
                                .stroke(
                                    neonCyan.opacity(0.2),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                
                                Path { path in
                                    path.move(to: targetPoints[0])
                                    for pt in targetPoints.dropFirst() { path.addLine(to: pt) }
                                }
                                .stroke(
                                    neonOrange.opacity(0.8),
                                    style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                                )
                                
                                // Vertex indicator
                                if let vertex = targetPoints.max(by: { $0.y > $1.y }) {
                                    Circle()
                                        .stroke(neonOrange, lineWidth: 1)
                                        .frame(width: 8, height: 8)
                                        .position(vertex)
                                    Text("VERTEX")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonOrange)
                                        .position(x: vertex.x, y: vertex.y - 12)
                                }
                            }
                            
                            // User path
                            if userPath.count > 1 {
                                Path { path in
                                    path.move(to: userPath[0])
                                    for pt in userPath.dropFirst() { path.addLine(to: pt) }
                                }
                                .stroke(neonCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .shadow(color: neonCyan.opacity(0.8), radius: 4)
                            }
                            
                            // Result overlay
                            if showResult {
                                ResultOverlay(
                                    accuracy: accuracy,
                                    onNext: nextLevel,
                                    onRetry: retry
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { v in
                                    if !showResult {
                                        if !isDrawing {
                                            userPath = [v.location]
                                            isDrawing = true
                                            updateLog("INPUT_DETECTED: CAPTURING_VECTOR")
                                        } else {
                                            userPath.append(v.location)
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    if isDrawing && !showResult {
                                        isDrawing = false
                                        updateLog("ANALYTIC_COMPLETION: CALCULATING_ERROR")
                                        calculateScore()
                                    }
                                }
                        )
                    }
                }
            }
        }
        .animation(.spring(), value: showResult)
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
    
    private func calculateScore() {
        guard !userPath.isEmpty && !targetPoints.isEmpty else { return }
        var totalDist = 0.0
        var samples = 0
        for uPt in userPath {
            let nearest = targetPoints.min(by: { dist($0, uPt) < dist($1, uPt) }) ?? targetPoints[0]
            totalDist += dist(nearest, uPt)
            samples += 1
        }
        let avgDist = totalDist / Double(samples)
        let norm = canvasSize.width / 320.0
        accuracy = max(0, min(1.0, 1.0 - avgDist / (40.0 * norm)))
        
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        updateLog("SCORE_MATRIX: \(pts) | ACC: \(Int(accuracy * 100))%")
        
        if accuracy > 0.6 { streak += 1 } else { streak = 0 }
        showResult = true
    }
    
    private func dist(_ a: CGPoint, _ b: CGPoint) -> Double {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
    
    private func nextLevel() {
        level = min(level + 1, 5)
        retry()
        updateLog("LEVEL_UP: PARAMETERS_RECONFIGURED")
    }
    
    private func retry() {
        userPath = []
        showResult = false
        accuracy = 0
    }
}

// MARK: - Scientist HUD Components

@available(iOS 16.0, *)
struct ScientificHUDOverlay: View {
    let level: Int
    let params: (v0: Double, angle: Double)
    let logs: [String]
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Label("KINEMATIC_VARS", systemImage: "function")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
                
                HUDDataRow(label: "V_INIT", value: "\(String(format: "%.2f", params.v0)) m/s")
                HUDDataRow(label: "THETA", value: "45.00°")
                HUDDataRow(label: "GRAVITY", value: "-9.81 m/s²")
            }
            .padding(10)
            .background(Color.black.opacity(0.4))
            .border(neonCyan.opacity(0.3), width: 1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("NEURAL_LINK: ACTIVE")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                ForEach(logs, id: \.self) { log in
                    Text("> \(log)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(neonCyan.opacity(0.7))
                }
            }
            .frame(width: 150, alignment: .trailing)
        }
    }
}

#endif

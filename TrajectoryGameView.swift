#if os(iOS)
import SwiftUI

// MARK: - Match Trajectory Game

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
    @State private var thinkingLog: [String] = ["SYSTEM_INIT: SUCCESS", "KINETIC_LINK: ESTABLISHED"]
    @State private var drawPulse = false
    
    // Physics parameters for the current level
    private var physicsParams: (v0: Double, angle: Double) {
        let v0 = 15.0 + Double(level) * 3.0
        let angle = Double.pi / 4.0
        return (v0, angle)
    }
    
    // Target points calculation
    private var targetPoints: [CGPoint] {
        guard canvasSize.width > 0 && canvasSize.height > 0 else { return [] }
        let g = 9.81
        let (v0, angle) = physicsParams
        
        let flightTime = 2.0 * v0 * sin(angle) / g
        let range = v0 * v0 * sin(2.0 * angle) / g
        let maxHeight = v0 * v0 * pow(sin(angle), 2) / (2 * g)
        
        let scaleX = (canvasSize.width * 0.80) / range
        let scaleY = (canvasSize.height * 0.60) / maxHeight
        let offsetX = canvasSize.width * 0.10
        let offsetY = canvasSize.height * 0.20
        
        var pts: [CGPoint] = []
        for i in stride(from: 0.0, through: flightTime, by: flightTime / 50.0) {
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
                GameHeader(
                    title: "TRAJECTORY_PROJECTION",
                    icon: "target",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonCyan, size: geo.size)
                            .onAppear { canvasSize = geo.size }
                    }
                    
                    VStack(spacing: 0) {
                        ScientificHUDOverlay(level: level, params: physicsParams, logs: thinkingLog)
                            .padding(16)
                        
                        if showHint {
                            FormulaCard(lines: [
                                "y = x·tan(θ) - (g·x²) / (2·v₀²·cos²(θ))",
                                "R = (v₀²·sin(2θ)) / g"
                            ], note: "Constant horizontal velocity, constant vertical acceleration.")
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        Spacer()
                        
                        // Interaction
                        ZStack {
                            // Target Path (Blueprint)
                            if !targetPoints.isEmpty {
                                Path { path in
                                    path.move(to: targetPoints[0])
                                    for pt in targetPoints.dropFirst() { path.addLine(to: pt) }
                                }
                                .stroke(neonCyan.opacity(0.1), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                
                                Path { path in
                                    path.move(to: targetPoints[0])
                                    for pt in targetPoints.dropFirst() { path.addLine(to: pt) }
                                }
                                .stroke(neonOrange.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                                
                                if let vertex = targetPoints.max(by: { $0.y > $1.y }) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "triangle.fill").font(.system(size: 8)).foregroundColor(neonOrange)
                                        Text("PEAK_Y").font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundColor(neonOrange)
                                    }
                                    .position(x: vertex.x, y: vertex.y - 12)
                                }
                            }
                            
                            // Draw path
                            if userPath.count > 1 {
                                Path { path in
                                    path.move(to: userPath[0])
                                    for pt in userPath.dropFirst() { path.addLine(to: pt) }
                                }
                                .stroke(
                                    LinearGradient(colors: [neonCyan, .blue], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                                )
                                .shadow(color: neonCyan.opacity(0.6), radius: 6)
                            }
                            
                            if isDrawing, let last = userPath.last {
                                Circle()
                                    .fill(neonCyan)
                                    .frame(width: 8, height: 8)
                                    .position(last)
                                    .scaleEffect(drawPulse ? 1.5 : 1.0)
                                    .opacity(drawPulse ? 0.3 : 1.0)
                                    .onAppear { withAnimation(.easeInOut(duration: 0.3).repeatForever()) { drawPulse = true } }
                            }
                            
                            if showResult {
                                ResultOverlay(accuracy: accuracy, onNext: nextLevel, onRetry: retry)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
                                            updateLog("CAPTURE: IN_PROGRESS")
                                        } else {
                                            userPath.append(v.location)
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    if isDrawing && !showResult {
                                        isDrawing = false
                                        updateLog("ANALYTIC: COMPUTING")
                                        calculateScore()
                                    }
                                }
                        )
                    }
                }
            }
        }
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
        accuracy = max(0, min(1.0, 1.0 - avgDist / 45.0))
        
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        updateLog("RESULT: \(Int(accuracy * 100))% MATCH")
        
        if accuracy > 0.6 { streak += 1 } else { streak = 0 }
        withAnimation(.spring()) { showResult = true }
    }
    
    private func dist(_ a: CGPoint, _ b: CGPoint) -> Double { sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2)) }
    private func nextLevel() { level = min(level + 1, 10); retry() }
    private func retry() { userPath = []; showResult = false; accuracy = 0; updateLog("SIM_RECALIBRATED") }
}

struct ScientificHUDOverlay: View {
    let level: Int
    let params: (v0: Double, angle: Double)
    let logs: [String]
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "cpu").font(.system(size: 10)).foregroundColor(neonCyan)
                    Text("EXP_VARS").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.white.opacity(0.6))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HUDDataRow(label: "V_INIT", value: "\(String(format: "%.1f", params.v0)) m/s")
                    HUDDataRow(label: "THETA", value: "45.0°")
                    HUDDataRow(label: "GRAVITY", value: "-9.81 m/s²")
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonCyan.opacity(0.2), lineWidth: 1))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 4, height: 4)
                    Text("LIVE_FEED").font(.system(size: 7, weight: .bold, design: .monospaced)).foregroundColor(.green)
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(logs, id: \.self) { log in
                        Text("> \(log)")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(neonCyan.opacity(0.6))
                    }
                }
                .frame(width: 140, alignment: .trailing)
            }
        }
    }
}

#endif

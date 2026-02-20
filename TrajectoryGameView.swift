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
    
    // Physics: target parabola parameters for the level
    private var targetPoints: [CGPoint] {
        guard canvasSize.width > 0 else { return [] }
        let g = 9.81, angle = Double.pi / 4.0 + Double.pi / 20.0 * Double(level - 1)
        let v0 = 12.0 + Double(level) * 2.0
        let scaleX = canvasSize.width / 340.0
        let scaleY = canvasSize.height / 260.0
        var pts: [CGPoint] = []
        for i in stride(from: 0.0, through: 200.0, by: 3.0) {
            let t = i / 60.0
            let x = v0 * cos(angle) * t
            let y = v0 * sin(angle) * t - 0.5 * g * t * t
            if y < 0 { break }
            pts.append(CGPoint(x: 20.0 + x * 5.0 * scaleX, y: canvasSize.height - 20.0 - y * 6.0 * scaleY))
        }
        return pts
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                GameHeader(
                    title: "MATCH TRAJECTORY",
                    icon: "arrow.up.right.circle.fill",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { showHint.toggle() }
                )
                
                // Formula hint
                if showHint {
                    FormulaCard(lines: [
                        "y = v₀·sinθ·t − ½·g·t²",
                        "x = v₀·cosθ·t",
                        "Range = v₀²·sin(2θ)/g"
                    ], note: "Draw the curve of a projectile launched at angle θ")
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Instructions
                Text(showResult ? "" : "DRAG YOUR FINGER ALONG THE TARGET PATH")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan.opacity(0.5))
                    .padding(.top, 8)
                
                // Canvas
                GeometryReader { geo in
                    ZStack {
                        // Grid background
                        GridBackground(color: neonCyan, size: geo.size)
                        
                        // Target path
                        if !targetPoints.isEmpty {
                            Path { path in
                                path.move(to: targetPoints[0])
                                for pt in targetPoints.dropFirst() { path.addLine(to: pt) }
                            }
                            .stroke(
                                neonOrange.opacity(0.6),
                                style: StrokeStyle(lineWidth: 3, dash: [8, 4])
                            )
                            
                            // Launch & landing labels
                            Circle()
                                .fill(neonGreen)
                                .frame(width: 12, height: 12)
                                .position(targetPoints.first ?? .zero)
                            
                            Text("LAUNCH")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(neonGreen)
                                .position(x: (targetPoints.first?.x ?? 0) + 25, y: (targetPoints.first?.y ?? 0) - 10)
                            
                            Circle()
                                .fill(neonOrange)
                                .frame(width: 12, height: 12)
                                .position(targetPoints.last ?? .zero)
                            
                            Text("LAND")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(neonOrange)
                                .position(x: (targetPoints.last?.x ?? 0) - 20, y: (targetPoints.last?.y ?? 0) - 14)
                        }
                        
                        // User path
                        if userPath.count > 1 {
                            Path { path in
                                path.move(to: userPath[0])
                                for pt in userPath.dropFirst() { path.addLine(to: pt) }
                            }
                            .stroke(neonCyan, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        }
                        
                        // Result overlay
                        if showResult {
                            ResultOverlay(
                                accuracy: accuracy,
                                onNext: nextLevel,
                                onRetry: retry
                            )
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                if !showResult {
                                    if !isDrawing {
                                        userPath = [v.location]
                                        isDrawing = true
                                    } else {
                                        userPath.append(v.location)
                                    }
                                }
                            }
                            .onEnded { _ in
                                if isDrawing && !showResult {
                                    isDrawing = false
                                    calculateScore(canvasSize: geo.size)
                                }
                            }
                    )
                    .onAppear { canvasSize = geo.size }
                    .onChange(of: geo.size) { newSize in canvasSize = newSize }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(neonCyan.opacity(0.2), lineWidth: 1)
                )
                .padding(12)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showHint)
        .animation(.easeInOut(duration: 0.3), value: showResult)
    }
    
    private func calculateScore(canvasSize: CGSize) {
        guard !userPath.isEmpty && !targetPoints.isEmpty else { return }
        var totalDist = 0.0
        var samples = 0
        for uPt in userPath {
            let nearest = targetPoints.min(by: { p1, p2 in
                dist(p1, uPt) < dist(p2, uPt)
            }) ?? targetPoints[0]
            totalDist += dist(nearest, uPt)
            samples += 1
        }
        let avgDist = totalDist / Double(samples)
        let norm = canvasSize.width / 320.0
        accuracy = max(0, min(1.0, 1.0 - avgDist / (60.0 * norm)))
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        if accuracy > 0.6 { streak += 1 } else { streak = 0 }
        showResult = true
    }
    
    private func dist(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = a.x - b.x, dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func nextLevel() {
        level = min(level + 1, 5)
        retry()
    }
    
    private func retry() {
        userPath = []
        showResult = false
        accuracy = 0
    }
}
#endif

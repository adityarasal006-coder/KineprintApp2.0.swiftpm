#if os(iOS)
import SwiftUI

// MARK: - Shared Game UI Components
// Used by TrajectoryGameView, VelocityGameView, OscillationGameView, LandingGameView

@MainActor
struct GameHeader: View {
    let title: String
    let icon: String
    let level: Int
    let score: Int
    let streak: Int
    let onDismiss: () -> Void
    let onHint: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                Button(action: onDismiss) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(neonCyan.opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .foregroundColor(neonCyan)
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text("SYSTEM_LINK: ACTIVE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Status Badges
                HStack(spacing: 8) {
                    if streak > 0 {
                        HStack(spacing: 4) {
                            Text("🔥")
                            Text("\(streak)")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                        .scaleEffect(1.1)
                    }
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("TOTAL_ACC")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("\(score)")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
                
                // Hint button
                Button(action: onHint) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    Color.black
                    LinearGradient(colors: [Color.white.opacity(0.05), .clear], startPoint: .top, endPoint: .bottom)
                }
            )
            
            Rectangle()
                .fill(LinearGradient(colors: [neonCyan.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
        }
    }
}

// MARK: - Formula Hint Card

@MainActor
struct FormulaCard: View {
    let lines: [String]
    let note: String
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "function")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.yellow)
                Text("FORMULA HINTS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
            
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
                    .padding(.leading, 4)
            }
            
            Text(note)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.yellow.opacity(0.06)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}

// MARK: - Grid Background

@MainActor
struct GridBackground: View {
    let color: Color
    let size: CGSize
    @State private var scanPos: CGFloat = 0
    @State private var opac: Double = 0.0
    
    var body: some View {
        let physicsFormulas = ["F = m·a", "v = u + a·t", "E = m·c²", "p = m·v", "τ = r × F", "K = ½·m·v²", "ω = v / r", "W = F·d·cos(θ)"]
        
        ZStack {
            Color.black
            
            FloatingFormulasView(formulas: physicsFormulas, color: color).ignoresSafeArea()
            
            // Subtle Radial Glow
            RadialGradient(colors: [color.opacity(0.08), .clear], center: .center, startRadius: 0, endRadius: max(size.width, size.height))
                .ignoresSafeArea()
            
            let spacing: CGFloat = 30
            let colCount = Int(size.width / spacing) + 1
            let rowCount = Int(size.height / spacing) + 1
            
            Group {
                ForEach(0..<colCount, id: \.self) { i in
                    Path { p in
                        p.move(to: CGPoint(x: CGFloat(i) * spacing, y: 0))
                        p.addLine(to: CGPoint(x: CGFloat(i) * spacing, y: size.height))
                    }
                    .stroke(color.opacity(0.06), lineWidth: 0.5)
                }
                ForEach(0..<rowCount, id: \.self) { i in
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: CGFloat(i) * spacing))
                        p.addLine(to: CGPoint(x: size.width, y: CGFloat(i) * spacing))
                    }
                    .stroke(color.opacity(0.06), lineWidth: 0.5)
                }
            }
            .opacity(opac)
            
            // Neon scan line
            ZStack {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, color.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 120)
                Rectangle()
                    .fill(color.opacity(0.5))
                    .frame(height: 1)
                    .shadow(color: color, radius: 4)
            }
            .offset(y: -60 + scanPos * (size.height + 120))
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) { opac = 1.0 }
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                scanPos = 1.0
            }
        }
    }
}

// MARK: - Result Overlay (used by TrajectoryGameView)

@MainActor
struct ResultOverlay: View {
    let accuracy: Double
    let onNext: () -> Void
    let onRetry: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var grade: String {
        if accuracy > 0.85 { return "PERFECT_SIMULATION" }
        else if accuracy > 0.65 { return "HIGH_ACCURACY_DETECTED" }
        else if accuracy > 0.45 { return "MARGINAL_STABILITY" }
        else { return "CALIBRATION_REQUIRED" }
    }
    
    var gradeColor: Color {
        if accuracy > 0.65 { return neonCyan }
        else if accuracy > 0.45 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        ZStack {
            if accuracy > 0.8 {
                ConfettiBurstView(color: neonCyan)
            }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    ZStack {
                        Circle().stroke(gradeColor.opacity(0.3), lineWidth: 1).frame(width: 44, height: 44)
                        Image(systemName: accuracy > 0.65 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(gradeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(grade)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(gradeColor)
                        Text("ANALYTIC_REPORT_v2.0")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                
                // Accuracy meter
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("MATCH_PRECISION")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(accuracy * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(gradeColor)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(gradeColor)
                                .frame(width: geo.size.width * accuracy)
                                .shadow(color: gradeColor.opacity(0.5), radius: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onRetry) {
                        Text("RE-CALIBRATE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                    }
                    Button(action: onNext) {
                        Text("CONTINUE_EXP")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(gradeColor)
                            .cornerRadius(10)
                            .shadow(color: gradeColor.opacity(0.3), radius: 8)
                    }
                }
            }
            .padding(24)
            .background(
                ZStack {
                    Color.black.opacity(0.9)
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(gradeColor.opacity(0.3), lineWidth: 1)
                }
            )
            .cornerRadius(20)
            .padding(.horizontal, 30)
        }
    }
}
struct ScientificSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text(String(format: "%.1f %@", value, unit))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            Slider(value: $value, in: range)
                .tint(color)
        }
    }
}

struct HUDDataRow: View {
    let label: String
    let value: String
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan)
        }
        .frame(width: 100)
    }
}
struct ConfettiBurstView: View {
    let color: Color
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speedY: CGFloat
        var speedX: CGFloat
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Rectangle()
                    .fill(color)
                    .frame(width: p.size, height: p.size)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
        .onAppear {
            spawnParticles()
        }
    }
    
    private func spawnParticles() {
        for _ in 0..<50 {
            particles.append(Particle(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
                size: CGFloat.random(in: 4...10),
                opacity: 1.0,
                speedY: CGFloat.random(in: -15...15),
                speedX: CGFloat.random(in: -15...15)
            ))
        }
        
        Task { @MainActor in
            while true {
                try? await Task.sleep(nanoseconds: 20_000_000) // 0.02s
                guard !Task.isCancelled else { break }
                
                for i in particles.indices {
                    particles[i].x += particles[i].speedX
                    particles[i].y += particles[i].speedY
                    particles[i].speedY += 0.5 // gravity
                    particles[i].opacity -= 0.015
                }
                
                if particles.allSatisfy({ $0.opacity <= 0 }) {
                    break
                }
            }
        }
    }
}
#endif

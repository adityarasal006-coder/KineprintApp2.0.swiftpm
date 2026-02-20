#if os(iOS)
import SwiftUI

// MARK: - Shared Game UI Components
// Used by TrajectoryGameView, VelocityGameView, OscillationGameView, LandingGameView

@available(iOS 16.0, *)
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
            HStack(alignment: .center, spacing: 12) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }
                
                Image(systemName: icon)
                    .foregroundColor(neonCyan)
                    .font(.system(size: 18, weight: .bold))
                
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
                    .lineLimit(1)
                
                Spacer()
                
                // Streak badge
                if streak > 0 {
                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.system(size: 14))
                        Text("×\(streak)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                
                // Score
                VStack(alignment: .trailing, spacing: 1) {
                    Text("LV \(level)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("\(score)")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundColor(neonCyan)
                }
                
                // Hint button
                Button(action: onHint) {
                    Image(systemName: "lightbulb.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.yellow.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            
            Rectangle()
                .fill(neonCyan.opacity(0.25))
                .frame(height: 1)
        }
    }
}

// MARK: - Formula Hint Card

@available(iOS 16.0, *)
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

@available(iOS 16.0, *)
@MainActor
struct GridBackground: View {
    let color: Color
    let size: CGSize
    
    var body: some View {
        ZStack {
            Color.black
            let colCount = Int(size.width / 30) + 1
            let rowCount = Int(size.height / 30) + 1
            
            ForEach(0..<colCount, id: \.self) { i in
                Path { p in
                    p.move(to: CGPoint(x: Double(i) * 30, y: 0))
                    p.addLine(to: CGPoint(x: Double(i) * 30, y: size.height))
                }
                .stroke(color.opacity(0.07), lineWidth: 0.5)
            }
            ForEach(0..<rowCount, id: \.self) { i in
                Path { p in
                    p.move(to: CGPoint(x: 0, y: Double(i) * 30))
                    p.addLine(to: CGPoint(x: size.width, y: Double(i) * 30))
                }
                .stroke(color.opacity(0.07), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Result Overlay (used by TrajectoryGameView)

@available(iOS 16.0, *)
@MainActor
struct ResultOverlay: View {
    let accuracy: Double
    let onNext: () -> Void
    let onRetry: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var grade: String {
        if accuracy > 0.85 { return "PERFECT TRAJECTORY! 🎯" }
        else if accuracy > 0.65 { return "NICE CURVE! ✅" }
        else if accuracy > 0.45 { return "GETTING THERE 📈" }
        else { return "KEEP PRACTICING 🔄" }
    }
    
    var gradeColor: Color {
        if accuracy > 0.65 { return neonCyan }
        else if accuracy > 0.45 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 14) {
            Text(grade)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(gradeColor)
                .multilineTextAlignment(.center)
            
            // Accuracy meter
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "ACCURACY: %.0f%%", accuracy * 100))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(gradeColor)
                            .frame(width: geo.size.width * accuracy)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 30)
            
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("RETRY", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(Color.gray)
                        .cornerRadius(10)
                }
                Button(action: onNext) {
                    Label("NEXT LEVEL", systemImage: "chevron.right.2")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(neonCyan)
                        .cornerRadius(10)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: neonCyan.opacity(0.2), radius: 20)
        .padding(.horizontal, 30)
    }
}
#endif

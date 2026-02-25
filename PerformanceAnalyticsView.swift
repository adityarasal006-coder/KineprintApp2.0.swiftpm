import SwiftUI

struct PerformanceAnalyticsView: View {
    @Binding var isPresented: Bool
    
    @AppStorage("trajectoryScore") private var trajectoryScore = 0
    @AppStorage("velocityScore") private var velocityScore = 0
    @AppStorage("oscillationScore") private var oscillationScore = 0
    @AppStorage("landingScore") private var landingScore = 0
    @AppStorage("momentumScore") private var momentumScore = 0
    @AppStorage("collisionScore") private var collisionScore = 0
    @AppStorage("centripetalScore") private var centripetalScore = 0
    @AppStorage("energyScore") private var energyScore = 0
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    @State private var selectedTimeframe = 0 // 0: Daily, 1: Weekly, 2: Monthly, 3: Yearly
    @State private var isAnimating = false
    
    private var totalGameScore: Int {
        trajectoryScore + velocityScore + oscillationScore + landingScore +
        momentumScore + collisionScore + centripetalScore + energyScore
    }
    
    private let timeframes = ["DAILY", "WEEKLY", "MONTHLY", "YEARLY"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background Grid and Tech overlay
            GeometryReader { geo in
                ZStack {
                    Path { path in
                        for i in stride(from: 0, to: geo.size.width, by: 40) {
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i, y: geo.size.height))
                        }
                        for i in stride(from: 0, to: geo.size.height, by: 40) {
                            path.move(to: CGPoint(x: 0, y: i))
                            path.addLine(to: CGPoint(x: geo.size.width, y: i))
                        }
                    }
                    .stroke(neonCyan.opacity(0.05), lineWidth: 1)
                    
                    Circle()
                        .fill(RadialGradient(colors: [neonCyan.opacity(0.15), .clear], center: .center, startRadius: 10, endRadius: 300))
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .position(x: geo.size.width / 2, y: geo.size.height / 3)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation { isPresented = false }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(neonCyan)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("DATA CENTER")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(neonCyan)
                            .tracking(2)
                        Text("PERFORMANCE ANALYTICS NODE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Image(systemName: "server.rack")
                        .foregroundColor(neonCyan)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .border(width: 1, edges: [.bottom], color: neonCyan.opacity(0.3))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Timeframe Selector
                        HStack(spacing: 0) {
                            ForEach(0..<4) { index in
                                Button(action: {
                                    withAnimation(.spring()) {
                                        selectedTimeframe = index
                                    }
                                }) {
                                    Text(timeframes[index])
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(selectedTimeframe == index ? .black : neonCyan)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(selectedTimeframe == index ? neonCyan : Color.clear)
                                }
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Total Score Metric
                        VStack(spacing: 8) {
                            Text("CUMULATIVE XP POOL")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            let multiplier = selectedTimeframe == 0 ? 0.05 : (selectedTimeframe == 1 ? 0.3 : (selectedTimeframe == 2 ? 0.8 : 1.0))
                            let displayedScore = Int(Double(totalGameScore) * multiplier)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(displayedScore)")
                                    .font(.system(size: 48, weight: .black, design: .monospaced))
                                    .foregroundColor(neonCyan)
                                    .contentTransition(.numericText())
                                Text("XP")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03))
                                RoundedRectangle(cornerRadius: 16).stroke(neonCyan.opacity(0.2), lineWidth: 1)
                            }
                        )
                        .padding(.horizontal)
                        
                        // Simulated Graph
                        VStack(spacing: 12) {
                            HStack {
                                Text("PERFORMANCE TRENDS")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "chart.xyaxis.line")
                                    .foregroundColor(neonCyan)
                            }
                            
                            HStack(alignment: .bottom, spacing: 12) {
                                ForEach(0..<7) { i in
                                    let height = CGFloat.random(in: 30...120) * (isAnimating ? 1 : 0.2)
                                    VStack {
                                        Spacer()
                                        Rectangle()
                                            .fill(LinearGradient(colors: [neonCyan, neonCyan.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                                            .frame(width: 20, height: height)
                                            .cornerRadius(4)
                                    }
                                    .frame(height: 120)
                                }
                            }
                            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: selectedTimeframe)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isAnimating)
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(neonCyan.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal)
                        
                        // Breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MODULE BREAKDOWN")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 12) {
                                MetricRow(title: "KINEMATICS (Trajectory/Velocity)", value: trajectoryScore + velocityScore, total: totalGameScore, color: .orange)
                                MetricRow(title: "DYNAMICS (Collision/Momentum)", value: collisionScore + momentumScore, total: totalGameScore, color: .green)
                                MetricRow(title: "FORCES (Landing/Centripetal)", value: landingScore + centripetalScore, total: totalGameScore, color: .purple)
                                MetricRow(title: "ENERGY & WAVES (Energy/Oscillation)", value: energyScore + oscillationScore, total: totalGameScore, color: .cyan)
                            }
                        }
                        .padding(20)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(neonCyan.opacity(0.2), lineWidth: 1))
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: Int
    let total: Int
    let color: Color
    
    @State private var animatedValue: CGFloat = 0.0
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(value)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(color)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    
                    let ratio = total > 0 ? CGFloat(value) / CGFloat(total) : 0
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * animatedValue)
                        .shadow(color: color.opacity(0.6), radius: 4)
                        .onAppear {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                                animatedValue = ratio
                            }
                        }
                }
            }
            .frame(height: 8)
        }
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}

import SwiftUI

// MARK: - ConceptVisualizer
// 100% STATIC — Zero animations, zero timers, zero threads.
// Each card renders a clean educational diagram that costs 0% CPU.

struct ConceptVisualizer: View {
    let code: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            // Static Diagram Area
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.5))
                
                staticDiagram(for: code)
                    .padding(12)
            }
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            
            // Annotation Bar
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(getLiveAnnotation(for: code))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.75))
            .cornerRadius(10)
        }
    }

    // MARK: - Static Diagram Router
    private func staticDiagram(for code: String) -> AnyView {
        switch code {
        // ═══════ MATHEMATICS ═══════
        case "MTH-001": return AnyView(eulerDiagram)
        case "MTH-002": return AnyView(navierDiagram)
        case "MTH-003": return AnyView(eigenDiagram)
        case "MTH-004": return AnyView(fourierDiagram)
        case "MTH-005": return AnyView(taylorDiagram)
        case "MTH-006": return AnyView(riemannDiagram)
        // ═══════ QUANTUM ═══════
        case "QTM-001": return AnyView(schrodingerDiagram)
        case "QTM-002": return AnyView(heisenbergDiagram)
        case "QTM-003": return AnyView(entanglementDiagram)
        case "QTM-004": return AnyView(collapseDiagram)
        case "QTM-005": return AnyView(tunnelingDiagram)
        case "QTM-006": return AnyView(pauliDiagram)
        // ═══════ AI & IOT ═══════
        case "AIO-001": return AnyView(backpropDiagram)
        case "AIO-002": return AnyView(shannonDiagram)
        case "AIO-003": return AnyView(mqttDiagram)
        case "AIO-004": return AnyView(gradientDiagram)
        case "AIO-005": return AnyView(convDiagram)
        case "AIO-006": return AnyView(edgeDiagram)
        // ═══════ ENGINEERING ═══════
        case "ENG-001": return AnyView(maxwellDiagram)
        case "ENG-002": return AnyView(bernoulliDiagram)
        case "ENG-003": return AnyView(braggDiagram)
        case "ENG-004": return AnyView(hookeDiagram)
        case "ENG-005": return AnyView(bandGapDiagram)
        // ═══════ KINEMATICS ═══════
        case "KIN-001": return AnyView(dampingDiagram)
        case "KIN-002": return AnyView(escapeDiagram)
        case "KIN-003": return AnyView(newtonDiagram)
        case "KIN-004": return AnyView(momentumDiagram)
        case "KIN-005": return AnyView(rotationalDiagram)
        case "KIN-006": return AnyView(centripetalDiagram)
        case "KIN-007": return AnyView(workEnergyDiagram)
        default:
            return AnyView(
                Image(systemName: "cpu")
                    .font(.system(size: 36))
                    .foregroundColor(color)
            )
        }
    }

    // ═══════════════════════════════════════════
    // MARK: - MATHEMATICS DIAGRAMS
    // ═══════════════════════════════════════════

    private var eulerDiagram: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: 70, height: 70)
                // Axes
                Rectangle().fill(Color.white.opacity(0.2)).frame(width: 70, height: 1)
                Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 70)
                // Point at -1
                Circle().fill(color).frame(width: 8, height: 8).offset(x: -35)
                Text("−1").font(.system(size: 8, weight: .bold)).foregroundColor(.white).offset(x: -35, y: 12)
                Text("Re").font(.system(size: 7)).foregroundColor(.gray).offset(x: 30, y: 8)
                Text("Im").font(.system(size: 7)).foregroundColor(.gray).offset(x: 8, y: -30)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("e^(iπ) + 1 = 0")
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Unit circle traversal\nhits Real axis at −1")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var navierDiagram: some View {
        HStack(spacing: 12) {
            VStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    HStack(spacing: 2) {
                        ForEach(0..<8, id: \.self) { j in
                            Image(systemName: "arrow.right")
                                .font(.system(size: 7))
                                .foregroundColor(color.opacity(Double(8 - j) / 10.0))
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Velocity Field")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Laminar → Turbulent")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.orange)
                Text("ρ(∂v/∂t) = −∇p + μ∇²v")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var eigenDiagram: some View {
        HStack(spacing: 16) {
            ZStack {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(color)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(.red.opacity(0.6))
                    .offset(x: -4, y: 4)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Ax = λx")
                    .font(.system(size: 16, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Vector stretches\nwithout rotating")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var fourierDiagram: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    ForEach(0..<10, id: \.self) { i in
                        let h = CGFloat([20, 35, 50, 40, 25, 55, 30, 45, 15, 38][i])
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color.opacity(Double(i + 3) / 12.0))
                            .frame(width: 4, height: h)
                    }
                }
                Text("Spectrum").font(.system(size: 7)).foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("F(ω) = ∫f(t)e^(−jωt)dt")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Signal → Frequencies")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
    }

    private var taylorDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Text("n=0").font(.system(size: 7)).foregroundColor(.gray)
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.3)).frame(width: 40, height: 3)
                }
                HStack(spacing: 4) {
                    Text("n=1").font(.system(size: 7)).foregroundColor(.gray)
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.5)).frame(width: 50, height: 3)
                }
                HStack(spacing: 4) {
                    Text("n=3").font(.system(size: 7)).foregroundColor(.gray)
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.7)).frame(width: 55, height: 3)
                }
                HStack(spacing: 4) {
                    Text("n=∞").font(.system(size: 7)).foregroundColor(.white)
                    RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 60, height: 3)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Σ f⁽ⁿ⁾(a)/n! · (x−a)ⁿ")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("More terms →\nbetter fit")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var riemannDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("Critical Line").font(.system(size: 8, weight: .bold)).foregroundColor(.yellow)
                Rectangle().fill(.yellow.opacity(0.6)).frame(width: 2, height: 60)
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(color).frame(width: 6, height: 6)
                    }
                }
                Text("Re(s) = ½").font(.system(size: 7)).foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("ζ(s) = 0")
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("All non-trivial zeros\nalign on one line")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    // ═══════════════════════════════════════════
    // MARK: - QUANTUM DIAGRAMS
    // ═══════════════════════════════════════════

    private var schrodingerDiagram: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 60, height: 60)
                Circle().fill(color.opacity(0.25)).frame(width: 40, height: 40)
                Circle().fill(color.opacity(0.5)).frame(width: 20, height: 20)
                Circle().fill(.white).frame(width: 6, height: 6)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("iℏ ∂Ψ/∂t = HΨ")
                    .font(.system(size: 12, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Probability cloud\ndenser = more likely")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var heisenbergDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text("Δx").font(.system(size: 10, weight: .bold)).foregroundColor(color)
                    Image(systemName: "arrow.left.and.right").font(.system(size: 9)).foregroundColor(.white)
                    Rectangle().fill(color).frame(width: 30, height: 6).cornerRadius(3)
                }
                HStack(spacing: 4) {
                    Text("Δp").font(.system(size: 10, weight: .bold)).foregroundColor(.orange)
                    Image(systemName: "arrow.left.and.right").font(.system(size: 9)).foregroundColor(.white)
                    Rectangle().fill(.orange).frame(width: 50, height: 6).cornerRadius(3)
                }
                Text("Δx↓ = Δp↑").font(.system(size: 8, weight: .bold)).foregroundColor(.yellow)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("ΔxΔp ≥ ℏ/2")
                    .font(.system(size: 12, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Precision tradeoff")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var entanglementDiagram: some View {
        HStack(spacing: 8) {
            VStack(spacing: 4) {
                Image(systemName: "atom").font(.system(size: 24)).foregroundColor(color)
                Text("State A").font(.system(size: 8, weight: .bold)).foregroundColor(color)
                Text("|↑⟩").font(.system(size: 12, weight: .bold, design: .serif)).foregroundColor(.white)
            }
            VStack(spacing: 2) {
                Image(systemName: "link").font(.system(size: 14)).foregroundColor(.yellow)
                Text("LINKED").font(.system(size: 7, weight: .bold)).foregroundColor(.yellow)
            }
            VStack(spacing: 4) {
                Image(systemName: "atom").font(.system(size: 24)).foregroundColor(.orange)
                Text("State B").font(.system(size: 8, weight: .bold)).foregroundColor(.orange)
                Text("|↓⟩").font(.system(size: 12, weight: .bold, design: .serif)).foregroundColor(.white)
            }
        }
    }

    private var collapseDiagram: some View {
        HStack(spacing: 10) {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                    Text("?").font(.system(size: 20, weight: .black)).foregroundColor(color)
                }
                Text("Superposition").font(.system(size: 7)).foregroundColor(.gray)
            }
            Image(systemName: "eye.fill").font(.system(size: 16)).foregroundColor(.yellow)
            Image(systemName: "arrow.right").font(.system(size: 12)).foregroundColor(.white)
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(color).frame(width: 40, height: 40)
                    Text("1").font(.system(size: 20, weight: .black)).foregroundColor(.black)
                }
                Text("Collapsed").font(.system(size: 7)).foregroundColor(.gray)
            }
        }
    }

    private var tunnelingDiagram: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 14, height: 14)
            Image(systemName: "arrow.right").font(.system(size: 10)).foregroundColor(.white)
            VStack(spacing: 0) {
                Rectangle().fill(.red.opacity(0.6)).frame(width: 20, height: 55)
                Text("Barrier").font(.system(size: 7)).foregroundColor(.red)
            }
            Image(systemName: "arrow.right").font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
            Circle().fill(color.opacity(0.5)).frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 4) {
                Text("T ≈ e^(−2κa)")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Wave leaks\nthrough wall")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var pauliDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up").font(.system(size: 14, weight: .bold)).foregroundColor(color)
                    Image(systemName: "arrow.down").font(.system(size: 14, weight: .bold)).foregroundColor(.orange)
                }
                RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.2)).frame(width: 40, height: 20)
                    .overlay(Text("n=1").font(.system(size: 8)).foregroundColor(.white))
                Text("Max 2 per state").font(.system(size: 7)).foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Ψ(1,2) = −Ψ(2,1)")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Opposite spins\nonly in same level")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    // ═══════════════════════════════════════════
    // MARK: - AI & IOT DIAGRAMS
    // ═══════════════════════════════════════════

    private var backpropDiagram: some View {
        HStack(spacing: 10) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(color.opacity(0.5)).frame(width: 12, height: 12)
                    }
                }
                HStack(spacing: 16) {
                    ForEach(0..<2, id: \.self) { _ in
                        Circle().fill(color).frame(width: 12, height: 12)
                    }
                }
                Circle().fill(.white).frame(width: 12, height: 12)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("∆w = −η(∂E/∂w)")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Error flows\nbackward ←")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
    }

    private var shannonDiagram: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 30))
                    .foregroundColor(color)
                HStack(spacing: 2) {
                    Text("S").font(.system(size: 9, weight: .bold)).foregroundColor(.green)
                    Text("/").font(.system(size: 9)).foregroundColor(.white)
                    Text("N").font(.system(size: 9, weight: .bold)).foregroundColor(.red)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("C = B log₂(1+S/N)")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Max data rate\nunder noise")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var mqttDiagram: some View {
        VStack(spacing: 8) {
            Image(systemName: "server.rack")
                .font(.system(size: 22))
                .foregroundColor(color)
            Text("BROKER").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(color)
            HStack(spacing: 30) {
                VStack(spacing: 2) {
                    Image(systemName: "sensor.fill").font(.system(size: 16)).foregroundColor(.white)
                    Text("PUB").font(.system(size: 7, weight: .bold)).foregroundColor(.green)
                }
                VStack(spacing: 2) {
                    Image(systemName: "iphone").font(.system(size: 16)).foregroundColor(.white)
                    Text("SUB").font(.system(size: 7, weight: .bold)).foregroundColor(.orange)
                }
            }
        }
    }

    private var gradientDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("Error").font(.system(size: 7)).foregroundColor(.red)
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<6, id: \.self) { i in
                        let heights: [CGFloat] = [40, 32, 24, 16, 10, 6]
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color.opacity(Double(6 - i) / 6.0))
                            .frame(width: 6, height: heights[i])
                    }
                }
                Text("Steps →").font(.system(size: 7)).foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("θ = θ − α∇J(θ)")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Descending to\nlowest error")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var convDiagram: some View {
        HStack(spacing: 10) {
            ZStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 36))
                    .foregroundColor(color.opacity(0.3))
                RoundedRectangle(cornerRadius: 2)
                    .stroke(.white, lineWidth: 2)
                    .frame(width: 14, height: 14)
            }
            Image(systemName: "arrow.right").foregroundColor(.white).font(.system(size: 10))
            Image(systemName: "square.grid.2x2.fill").font(.system(size: 24)).foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("Feature Map")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                Text("Filter scans image")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var edgeDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Image(systemName: "cpu").font(.system(size: 26)).foregroundColor(color)
                Text("EDGE").font(.system(size: 8, weight: .black)).foregroundColor(color)
                Text("Local AI").font(.system(size: 7)).foregroundColor(.white)
            }
            Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(.red)
            VStack(spacing: 4) {
                Image(systemName: "cloud").font(.system(size: 26)).foregroundColor(.gray.opacity(0.4))
                Text("CLOUD").font(.system(size: 8, weight: .bold)).foregroundColor(.gray)
                Text("Offline").font(.system(size: 7)).foregroundColor(.gray)
            }
        }
    }

    // ═══════════════════════════════════════════
    // MARK: - ENGINEERING DIAGRAMS
    // ═══════════════════════════════════════════

    private var maxwellDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill").font(.system(size: 14)).foregroundColor(.yellow)
                    Text("E").font(.system(size: 14, weight: .black)).foregroundColor(.yellow)
                }
                Text("⊥").font(.system(size: 16, weight: .black)).foregroundColor(.white)
                HStack(spacing: 4) {
                    Image(systemName: "magnet").font(.system(size: 14)).foregroundColor(.blue)
                    Text("B").font(.system(size: 14, weight: .black)).foregroundColor(.blue)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("∇×B = μ₀J + μ₀ε₀∂E/∂t")
                    .font(.system(size: 8, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("E ⊥ B fields\ninduce each other")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var bernoulliDiagram: some View {
        HStack(spacing: 10) {
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.3)).frame(width: 50, height: 20)
                    .overlay(Text("Wide").font(.system(size: 7)).foregroundColor(.white))
                RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.6)).frame(width: 24, height: 14)
                    .overlay(Text("Narrow").font(.system(size: 6)).foregroundColor(.white))
                RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.3)).frame(width: 50, height: 20)
                    .overlay(Text("Wide").font(.system(size: 7)).foregroundColor(.white))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("P + ½ρv² = const")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Narrow → Fast\nFast → Low P")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
    }

    private var braggDiagram: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        Circle().fill(color.opacity(0.5)).frame(width: 8, height: 8)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        Circle().fill(color.opacity(0.5)).frame(width: 8, height: 8)
                    }
                }
                Text("Crystal Planes").font(.system(size: 7)).foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("nλ = 2d sin(θ)")
                    .font(.system(size: 12, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("X-rays bounce\noff atom layers")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var hookeDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text("←F  x→").font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                Text("Linear").font(.system(size: 7)).foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("F = −kx")
                    .font(.system(size: 16, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Spring force opposes\ndisplacement")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var bandGapDiagram: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 50, height: 16)
                    .overlay(Text("Conduct.").font(.system(size: 7, weight: .bold)).foregroundColor(.black))
                RoundedRectangle(cornerRadius: 4).stroke(style: StrokeStyle(lineWidth: 1, dash: [3])).foregroundColor(.red).frame(width: 50, height: 12)
                    .overlay(Text("Gap").font(.system(size: 7, weight: .bold)).foregroundColor(.red))
                RoundedRectangle(cornerRadius: 4).fill(.orange).frame(width: 50, height: 16)
                    .overlay(Text("Valence").font(.system(size: 7, weight: .bold)).foregroundColor(.black))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Eg = Ec − Ev")
                    .font(.system(size: 12, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Electron must\njump forbidden gap")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    // ═══════════════════════════════════════════
    // MARK: - KINEMATICS DIAGRAMS
    // ═══════════════════════════════════════════

    private var dampingDiagram: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<7, id: \.self) { i in
                        let heights: [CGFloat] = [35, 25, 18, 13, 9, 6, 3]
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color.opacity(Double(7 - i) / 7.0))
                            .frame(width: 5, height: heights[i])
                    }
                }
                Text("Amplitude → 0").font(.system(size: 7)).foregroundColor(.gray)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("c = 2√(m·k)")
                    .font(.system(size: 12, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Critical = fastest\nreturn, no bounce")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var escapeDiagram: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(.blue.opacity(0.3)).frame(width: 40, height: 40)
                    .overlay(Text("M").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                    .offset(y: -30)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("v = √(2GM/r)")
                    .font(.system(size: 12, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Speed to break\nfree from gravity")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var newtonDiagram: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.yellow)
                RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.5)).frame(width: 30, height: 30)
                    .overlay(Text("m").font(.system(size: 12, weight: .bold)).foregroundColor(.white))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                Text("a").font(.system(size: 14, weight: .black)).foregroundColor(.orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("ΣF = ma")
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Force → Accel")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var momentumDiagram: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 20, height: 20)
                Image(systemName: "arrow.right").font(.system(size: 10)).foregroundColor(.white)
            }
            Text("💥").font(.system(size: 16))
            HStack(spacing: 4) {
                Image(systemName: "arrow.right").font(.system(size: 10)).foregroundColor(.white)
                RoundedRectangle(cornerRadius: 4).fill(.orange).frame(width: 20, height: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Σp = const")
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Momentum\ntransfers")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var rotationalDiagram: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(color.opacity(0.4), lineWidth: 2).frame(width: 50, height: 50)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Text("ω").font(.system(size: 10, weight: .black)).foregroundColor(.white).offset(y: -3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("I = Σ(mr²)")
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Mass distribution\nresists spin change")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var centripetalDiagram: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(color.opacity(0.3), lineWidth: 1).frame(width: 50, height: 50)
                Circle().fill(.white).frame(width: 8, height: 8).offset(x: 25)
                Image(systemName: "arrow.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yellow)
                    .offset(x: 12)
                Circle().fill(color).frame(width: 6, height: 6)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("ac = v²/r")
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Always points\nto center")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    private var workEnergyDiagram: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("K₁").font(.system(size: 10, weight: .bold)).foregroundColor(.orange)
                    Image(systemName: "plus").font(.system(size: 8)).foregroundColor(.white)
                    Text("W").font(.system(size: 10, weight: .bold)).foregroundColor(.yellow)
                    Image(systemName: "equal").font(.system(size: 8)).foregroundColor(.white)
                    Text("K₂").font(.system(size: 10, weight: .bold)).foregroundColor(color)
                }
                HStack(alignment: .bottom, spacing: 3) {
                    RoundedRectangle(cornerRadius: 2).fill(.orange).frame(width: 16, height: 18)
                    Text("+").font(.system(size: 8)).foregroundColor(.white)
                    RoundedRectangle(cornerRadius: 2).fill(.yellow).frame(width: 16, height: 12)
                    Text("=").font(.system(size: 8)).foregroundColor(.white)
                    RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 16, height: 30)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("W = ΔK")
                    .font(.system(size: 14, weight: .black, design: .serif))
                    .foregroundColor(.white)
                Text("Work done =\nenergy change")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }

    // ═══════════════════════════════════════════
    // MARK: - Live Annotation Text
    // ═══════════════════════════════════════════

    func getLiveAnnotation(for code: String) -> String {
        switch code {
        case "MTH-001": return "ANALYSIS: Unit circle traversal — rotation hits π, value lands at −1 on Real axis."
        case "MTH-002": return "ANALYSIS: Viscous fluid layers drag against each other, laminar → turbulent transition."
        case "MTH-003": return "ANALYSIS: Linear transform stretches the eigenvector without rotating it."
        case "MTH-004": return "ANALYSIS: Complex waveform decomposed into distinct frequency sine components."
        case "MTH-005": return "ANALYSIS: Adding polynomial terms progressively approximates the target function."
        case "MTH-006": return "ANALYSIS: Non-trivial zeros of ζ(s) all align on the critical line Re(s) = ½."

        case "QTM-001": return "ANALYSIS: Particle exists as probability cloud; denser region = higher chance."
        case "QTM-002": return "ANALYSIS: Squeezing position certainty forces momentum uncertainty to increase."
        case "QTM-003": return "ANALYSIS: Measuring one particle instantly determines the other's state."
        case "QTM-004": return "ANALYSIS: Observation forces superposition to collapse into a single eigenstate."
        case "QTM-005": return "ANALYSIS: Probability wave bleeds through barrier; particle appears on other side."
        case "QTM-006": return "ANALYSIS: Two fermions cannot occupy the exact same quantum state (Pauli)."

        case "AIO-001": return "ANALYSIS: Loss error propagates backward through layers to update weights."
        case "AIO-002": return "ANALYSIS: Channel capacity maxes out under the current signal-to-noise ratio."
        case "AIO-003": return "ANALYSIS: Lightweight pub/sub messaging — sensors publish, devices subscribe."
        case "AIO-004": return "ANALYSIS: Iteratively stepping down the error gradient toward global minimum."
        case "AIO-005": return "ANALYSIS: 3×3 filter kernel slides across pixels to extract a feature map."
        case "AIO-006": return "ANALYSIS: Local node processes AI independently — no cloud latency needed."

        case "ENG-001": return "ANALYSIS: Oscillating E field induces perpendicular B field — light is EM wave."
        case "ENG-002": return "ANALYSIS: Pipe constriction → velocity spike → local pressure drop."
        case "ENG-003": return "ANALYSIS: X-ray waves constructively interfere when reflecting off crystal planes."
        case "ENG-004": return "ANALYSIS: Restorative spring force opposes displacement linearly."
        case "ENG-005": return "ANALYSIS: Electron must jump the forbidden energy gap from valence to conduction."

        case "KIN-001": return "ANALYSIS: Oscillation amplitude decays to zero — critical damping is fastest."
        case "KIN-002": return "ANALYSIS: Kinetic velocity exceeds gravitational binding — object escapes orbit."
        case "KIN-003": return "ANALYSIS: Net force on mass directly produces proportional acceleration."
        case "KIN-004": return "ANALYSIS: Total momentum before collision equals total momentum after."
        case "KIN-005": return "ANALYSIS: Mass distribution about axis determines resistance to spin change."
        case "KIN-006": return "ANALYSIS: Continuous center-seeking acceleration curves path into circular orbit."
        case "KIN-007": return "ANALYSIS: Net work done on object converts directly to kinetic energy change."

        default: return "ANALYSIS: Scanning concept parameters..."
        }
    }
}

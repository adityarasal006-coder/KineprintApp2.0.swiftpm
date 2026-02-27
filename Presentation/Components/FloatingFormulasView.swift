import SwiftUI

struct FloatingFormulasView: View {
    let formulas: [String]
    let color: Color
    
    @State private var opacities: [Double] = Array(repeating: 0.0, count: 20)
    @State private var scales: [CGFloat] = Array(repeating: 0.5, count: 20)
    @State private var offsets: [CGFloat] = Array(repeating: 0.0, count: 20)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<20, id: \.self) { i in
                    Text(formulas[i % formulas.count])
                        .font(.system(size: CGFloat.random(in: 12...24), weight: .bold, design: .serif))
                        .foregroundColor(color.opacity(opacities[i]))
                        .scaleEffect(scales[i])
                        .position(
                            x: CGFloat(Int.random(in: 0...Int(geo.size.width))),
                            y: CGFloat(Int.random(in: 0...Int(geo.size.height)))
                        )
                        .offset(y: offsets[i])
                        .onAppear {
                            withAnimation(
                                Animation.linear(duration: Double.random(in: 10...30))
                                    .repeatForever(autoreverses: false)
                                    .delay(Double.random(in: 0...5))
                            ) {
                                offsets[i] = -geo.size.height * 1.5
                            }
                            withAnimation(
                                Animation.easeInOut(duration: Double.random(in: 2...5))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double.random(in: 0...2))
                            ) {
                                opacities[i] = Double.random(in: 0.1...0.4)
                                scales[i] = CGFloat.random(in: 0.8...1.2)
                            }
                        }
                }
            }
        }
        .allowsHitTesting(false)
        .opacity(0.8)
    }
}

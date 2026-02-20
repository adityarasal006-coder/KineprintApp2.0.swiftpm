#if os(iOS)
import SwiftUI

@available(iOS 16.0, *)
struct HomeDashboardView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var showingResearch = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Intro header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SYSTEM OVERVIEW")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("KINETIC ENGINEERING")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Featured Card (Explanation of the Theme)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "cpu")
                            .foregroundColor(neonCyan)
                        Text("ABOUT KINEPRINT")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Text("Kineprint is an advanced engineering tool focused on real-time kinematic printing principles. It allows operatives to analyze physical motion with LiDAR, interface with IoT components via Bluetooth, and train in kinetic concepts.")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.black.opacity(0.4))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(neonCyan.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 20)

                // Quick Stats / Summary
                HStack(spacing: 16) {
                    MetricCardView(title: "SENSORS", value: "8", icon: "sensor.tag.radiowaves.forward")
                    MetricCardView(title: "MODELS", value: "3D", icon: "cube.transparent.fill")
                }
                .padding(.horizontal, 20)
                
                // Research Folder Link
                Button(action: { showingResearch = true }) {
                    HStack {
                        Image(systemName: "folder.fill.badge.gearshape")
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RESEARCH FOLDER")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                            Text("\(viewModel.researchEntries.count) OBJECTS SCAN LOGGED")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(neonCyan)
                    .padding()
                    .background(neonCyan.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.3), lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .sheet(isPresented: $showingResearch) {
                    ResearchLibraryView(viewModel: viewModel)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    Text("OPERATIVE DIRECTIVES")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    DirectiveRow(step: "1", text: "Use the IoT Hub to pair with robotics hardware.")
                    DirectiveRow(step: "2", text: "Activate the AR Scanner to track motion and deep scan objects.")
                    DirectiveRow(step: "3", text: "Review saved scan data in the Research Folder above.")
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer().frame(height: 80) // bottom padding for tab bar
            }
            .padding(.top, 20)
        }
    }
}

@available(iOS 16.0, *)
struct MetricCardView: View {
    let title: String
    let value: String
    let icon: String
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(neonCyan)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(neonCyan.opacity(0.15), lineWidth: 1)
        )
    }
}

@available(iOS 16.0, *)
struct DirectiveRow: View {
    let step: String
    let text: String
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
                .background(neonCyan)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundColor(.gray)
                .lineSpacing(2)
        }
    }
}
#endif

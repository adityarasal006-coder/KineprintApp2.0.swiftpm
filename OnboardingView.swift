#if os(iOS)
import SwiftUI

@available(iOS 16.0, *)
struct OnboardingView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var currentPage = 0
    @State private var nameInput = ""
    @Environment(\.dismiss) var dismiss
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            // Background: Blueprint Grid Image/Effect
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    // Moving grid lines for flair
                    ForEach(0..<10) { i in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height / 10 * CGFloat(i)))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 10 * CGFloat(i)))
                        }
                        .stroke(neonCyan.opacity(0.1), lineWidth: 0.5)
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                TabView(selection: $currentPage) {
                    // Card 1: Identity - explain that Kineprint turns the device into a real-time kinematic lab
                    VStack(spacing: 24) {
                        Image(systemName: "scissors")
                            .font(.system(size: 60))
                            .foregroundColor(neonCyan)
                            .shadow(color: neonCyan.opacity(0.5), radius: 10)
                        
                        Text("KINEMATIC LAB")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Transform your device into a real-time mechanical diagnostic tool")
                            .font(.system(size: 14, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                    }
                    .tag(0)
                    
                    // Card 2: How Tracking Works - briefly explain LiDAR motion tracking in simple student language
                    OnboardingSlide(
                        icon: "lidar.topography",
                        title: "LIDAR TRACKING",
                        description: "LiDAR scans your environment to create precise 3D maps for accurate motion tracking.",
                        color: neonCyan
                    )
                    .tag(1)
                    
                    // Card 3: Buddy Setup - user chooses preferred name, assistant style (quiet or guided), measurement units
                    VStack(spacing: 24) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(neonCyan)
                            .shadow(color: neonCyan.opacity(0.5), radius: 10)
                        
                        Text("BUDDY SETUP")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Choose your preferred name and assistant style")
                            .font(.system(size: 14, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                        
                        TextField("YOUR NAME", text: $nameInput)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(nameInput.isEmpty ? Color.gray.opacity(0.3) : neonCyan, lineWidth: 1)
                            )
                            .foregroundColor(neonCyan)
                            .padding(.horizontal, 60)
                            .textInputAutocapitalization(.characters)
                        
                        // Assistant style picker
                        HStack {
                            Text("ASSISTANCE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Picker("Assistance", selection: $viewModel.assistantStyle) {
                                Text("Quiet").tag(AssistantStyle.quiet)
                                Text("Guided").tag(AssistantStyle.guided)
                            }
                            .pickerStyle(.segmented)
                            .scaleEffect(0.9)
                        }
                        .padding(.horizontal, 40)
                        
                        // Units picker
                        HStack {
                            Text("UNITS")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Picker("Units", selection: $viewModel.measurementUnits) {
                                Text("Metric").tag(MeasurementUnits.metric)
                                Text("Imperial").tag(MeasurementUnits.imperial)
                            }
                            .pickerStyle(.segmented)
                            .scaleEffect(0.9)
                        }
                        .padding(.horizontal, 40)
                    }
                    .tag(2)
                    
                    // Card 4: Permissions - request Camera, LiDAR, and Motion access with strong CTA
                    VStack(spacing: 24) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 60))
                            .foregroundColor(neonCyan)
                            .shadow(color: neonCyan.opacity(0.5), radius: 10)
                        
                        Text("PRIVACY NOTICE")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 10) {
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                    .padding(.top, 2)
                                Text("Camera access for AR scanning")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                    .padding(.top, 2)
                                Text("Motion sensors for tracking")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                    .padding(.top, 2)
                                Text("LiDAR for precise mapping")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        Text("All data stays on your device. No cloud required.")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            if !nameInput.isEmpty {
                                viewModel.completeOnboarding(with: nameInput)
                            }
                        }) {
                            Text("ENTER THE LAB")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 50)
                                .background(neonCyan)
                                .cornerRadius(10)
                                .shadow(color: neonCyan.opacity(0.4), radius: 15)
                        }
                        .padding(.top, 10)
                    }
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 500)
                
                Spacer()
                
                // Bottom indicator polish
                Text("KINEPRINT PROTOCOL v2.0")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan.opacity(0.4))
                    .padding(.bottom, 20)
            }
        }
    }
}

@available(iOS 16.0, *)
struct OnboardingSlide: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 20)
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.5), radius: 10)
            }
            
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text(description)
                .font(.system(size: 14, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
                .lineSpacing(4)
        }
    }
}
#endif

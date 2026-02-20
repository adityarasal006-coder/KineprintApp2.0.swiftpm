#if os(iOS)
import SwiftUI
import AudioToolbox
import AVFoundation

@available(iOS 16.0, *)
struct OnboardingView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var currentPage = 0
    @State private var nameInput = ""
    @State private var showGreeting = false
    @State private var greetingText = ""
    @Environment(\.dismiss) var dismiss
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 1 && hour < 12 {
            return "Good Morning"      // 1:00 AM – 11:59 AM
        } else if hour >= 12 && hour < 16 {
            return "Good Afternoon"    // 12:00 PM – 3:59 PM
        } else {
            return "Good Evening"      // 4:00 PM – 12:59 AM
        }
    }
    
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
                    // Card 1: Identity - Kinematic Lab with gear icon
                    VStack(spacing: 24) {
                        ZStack {
                            // Outer pulsing ring
                            Circle()
                                .stroke(neonCyan.opacity(0.15), lineWidth: 3)
                                .frame(width: 130, height: 130)
                            
                            Circle()
                                .stroke(neonCyan.opacity(0.25), lineWidth: 2)
                                .frame(width: 110, height: 110)
                            
                            // Inner glow circle
                            Circle()
                                .fill(neonCyan.opacity(0.08))
                                .frame(width: 100, height: 100)
                            
                            // Gear icon — represents kinematics/engineering
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(neonCyan)
                                .shadow(color: neonCyan.opacity(0.6), radius: 15)
                        }
                        
                        Text("KINEMATIC LAB")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Transform your device into a real-time mechanical diagnostic tool for engineering")
                            .font(.system(size: 14, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                    }
                    .tag(0)
                    
                    // Card 2: LiDAR Tracking with animated scan rings
                    VStack(spacing: 24) {
                        LiDARScanIcon(color: neonCyan)
                        
                        Text("LIDAR TRACKING")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("LiDAR scans your environment to create precise 3D maps for accurate motion tracking.")
                            .font(.system(size: 14, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 40)
                            .lineSpacing(4)
                    }
                    .tag(1)
                    
                    // Card 3: Buddy Setup — name only, with SAVE button
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(neonCyan.opacity(0.08))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 55))
                                .foregroundColor(neonCyan)
                                .shadow(color: neonCyan.opacity(0.5), radius: 10)
                        }
                        
                        Text("BUDDY SETUP")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Enter your name to get started")
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
                            .textInputAutocapitalization(.words)
                            .onSubmit {
                                saveName()
                            }
                        
                        // SAVE button for mobile
                        Button(action: {
                            saveName()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("SAVE")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(nameInput.isEmpty ? .gray : .black)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 50)
                            .background(nameInput.isEmpty ? Color.gray.opacity(0.3) : neonCyan)
                            .cornerRadius(12)
                            .shadow(color: nameInput.isEmpty ? .clear : neonCyan.opacity(0.4), radius: 10)
                        }
                        .disabled(nameInput.isEmpty)
                        .animation(.easeInOut, value: nameInput.isEmpty)
                    }
                    .tag(2)
                    
                    // Card 4: Permissions
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(neonCyan.opacity(0.08))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "camera.aperture")
                                .font(.system(size: 50))
                                .foregroundColor(neonCyan)
                                .shadow(color: neonCyan.opacity(0.5), radius: 10)
                        }
                        
                        Text("PRIVACY NOTICE")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 10) {
                            PermissionRow(text: "Camera access for AR scanning")
                            PermissionRow(text: "Motion sensors for tracking")
                            PermissionRow(text: "LiDAR for precise mapping")
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
            
            // Greeting overlay
            if showGreeting {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 16) {
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 50))
                        .foregroundColor(neonCyan)
                        .shadow(color: neonCyan.opacity(0.6), radius: 15)
                    
                    Text(greetingText)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .multilineTextAlignment(.center)
                    
                    Text(nameInput.uppercased())
                        .font(.system(size: 32, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                }
                .scaleEffect(showGreeting ? 1.0 : 0.5)
                .opacity(showGreeting ? 1.0 : 0)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showGreeting)
    }
    
    private func saveName() {
        guard !nameInput.isEmpty else { return }
        
        // Play a chime sound
        AudioServicesPlaySystemSound(1054)
        
        // Show time-based greeting
        greetingText = timeBasedGreeting + ","
        showGreeting = true
        
        // Speak greeting aloud
        speakGreeting()
        
        // Auto-advance to permissions page after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showGreeting = false
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage = 3
            }
        }
    }
    
    private func speakGreeting() {
        let synthesizer = AVSpeechSynthesizer()
        let name = nameInput.trimmingCharacters(in: .whitespaces)
        let greeting = timeBasedGreeting
        let text = "\(greeting), \(name)! Welcome to KinePrint. We are waiting for you to come back again!"
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = 1.1
        utterance.rate = 0.50
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }
}

// MARK: - Animated LiDAR Scan Icon

@available(iOS 16.0, *)
struct LiDARScanIcon: View {
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Animated scan rings
            ForEach(0..<3) { i in
                Circle()
                    .stroke(color.opacity(isAnimating ? 0.0 : 0.3), lineWidth: 2)
                    .frame(width: isAnimating ? 180 : 80, height: isAnimating ? 180 : 80)
                    .animation(
                        .easeOut(duration: 2.0)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.6),
                        value: isAnimating
                    )
            }
            
            // Static outer ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 20)
                .frame(width: 120, height: 120)
            
            // Inner glow
            Circle()
                .fill(color.opacity(0.08))
                .frame(width: 90, height: 90)
            
            // LiDAR icon
            Image(systemName: "sensor.tag.radiowaves.forward.fill")
                .font(.system(size: 40))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.6), radius: 12)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Permission Row

@available(iOS 16.0, *)
struct PermissionRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 12))
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}
#endif

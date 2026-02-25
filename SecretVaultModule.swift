import SwiftUI
import Speech
import AVFoundation

struct BreachPopup: Identifiable {
    let id = UUID()
    let text: String
    let position: CGPoint
    let color: Color
}

struct SystemBreachAnimationView: View {
    @Binding var isComplete: Bool
    @State private var phase = 0 // 0: auth, 1: bypass, 2: overload, 3: success
    @State private var screenShake: CGSize = .zero
    @State private var glitchOpacity: Double = 1.0
    @State private var logs1: [String] = []
    @State private var logs2: [String] = []
    @State private var popups: [BreachPopup] = []
    @State private var coreRotation: Double = 0
    @State private var flashRed = false
    @State private var viewScale: CGFloat = 1.0
    @State private var glitchBars: [CGFloat] = (0..<10).map { _ in CGFloat.random(in: 0...800) }
    
    let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    
    private let hexChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "X", "Y", "Z", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "="]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Backlayer Matrix Streams
            HStack(spacing: 0) {
                Text(logs1.joined(separator: "\n"))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(phase >= 2 ? .red : Color(red: 0, green: 1, blue: 0.85).opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: phase == 2 ? CGFloat.random(in: -20...20) : 0)
                
                Text(logs2.joined(separator: "\n"))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(phase >= 2 ? .red.opacity(0.8) : .white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .offset(x: phase == 2 ? CGFloat.random(in: -10...10) : 0)
            }
            .padding(.horizontal, 10)
            .offset(screenShake)
            
            // Aggressive Glitch Bars Overlay
            if phase == 2 {
                ForEach(glitchBars.indices, id: \.self) { i in
                    Rectangle()
                        .fill(Int.random(in: 0...1) == 0 ? Color.red : Color.black)
                        .frame(height: CGFloat.random(in: 2...15))
                        .offset(y: glitchBars[i] - 400)
                        .opacity(Double.random(in: 0.3...0.9))
                }
            }
            
            // Popups Array
            ForEach(popups) { popup in
                Text(popup.text)
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(popup.color)
                    .border(.white, width: phase >= 2 ? 2 : 0)
                    .position(popup.position)
                    .rotation3DEffect(.degrees(Double.random(in: -15...15)), axis: (x: 0, y: 0, z: 1))
            }
            
            // Core Breach Visualization
            VStack {
                Spacer()
                ZStack {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .stroke(phase >= 2 ? Color.red : Color(red: 0, green: 1, blue: 0.85), style: StrokeStyle(lineWidth: CGFloat(2 + i*2), dash: [CGFloat.random(in: 5...30), CGFloat.random(in: 5...20)]))
                            .frame(width: 100 + CGFloat(i * 40), height: 100 + CGFloat(i * 40))
                            .rotationEffect(.degrees(coreRotation * (i % 2 == 0 ? 1 : -1) * Double(i + 1)))
                            .scaleEffect(phase >= 2 ? CGFloat.random(in: 0.95...1.15) : 1.0)
                    }
                    
                    if phase < 3 {
                        Image(systemName: phase == 2 ? "exclamationmark.triangle.fill" : "lock.rotation")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(phase == 2 ? .white : Color(red: 0, green: 1, blue: 0.85))
                            .opacity(glitchOpacity)
                            .scaleEffect(phase == 2 ? 1.5 : 1.0)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.green)
                            .shadow(color: .green, radius: 20)
                    }
                }
                .offset(screenShake)
                Spacer()
                
                // Status Text
                VStack(spacing: 8) {
                    Text(statusText)
                        .font(.system(size: phase == 2 ? 24 : 16, weight: .heavy, design: .monospaced))
                        .foregroundColor(flashRed ? .white : (phase == 2 ? .red : (phase == 3 ? .green : .white)))
                        .background(flashRed ? Color.red : Color.clear)
                        .scaleEffect(phase == 2 ? CGFloat.random(in: 0.9...1.1) : 1.0)
                        
                    if phase == 1 {
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0, green: 1, blue: 0.85)))
                            .padding(.horizontal, 60)
                            .scaleEffect(y: 2, anchor: .center)
                    }
                }
                .padding(.bottom, 60)
            }
            
            // Full Screen Strobe Warning
            if flashRed {
                Color.red.opacity(0.3).ignoresSafeArea().blendMode(.plusLighter)
            }
        }
        .scaleEffect(viewScale)
        .onAppear {
            startAnimation()
        }
        .onReceive(timer) { _ in
            updateFrame()
        }
    }
    
    private var statusText: String {
        switch phase {
        case 0: return "VERIFYING SIGNATURE..."
        case 1: return "INJECTING PAYLOAD..."
        case 2: return "CRITICAL: SYSTEM OVERLOAD"
        case 3: return "VAULT ACCESS GRANTED"
        default: return ""
        }
    }
    
    private func updateFrame() {
        coreRotation += phase == 2 ? 15 : 4
        
        let randomLog1 = (0..<Int.random(in: 4...8)).map { _ in hexChars.randomElement()! }.joined()
        let randomLog2 = (0..<Int.random(in: 6...12)).map { _ in hexChars.randomElement()! }.joined()
        
        logs1.append("0x\(randomLog1) : \(phase == 2 ? "FATAL_ERR" : "OK")")
        logs2.append("SYS.DUMP[\(randomLog2)]")
        
        if logs1.count > (phase == 2 ? 60 : 35) { logs1.removeFirst() }
        if logs2.count > (phase == 2 ? 70 : 40) { logs2.removeFirst() }
        
        if phase >= 1 {
            glitchOpacity = Double.random(in: 0.2...1.0)
            if phase == 2 {
                screenShake = CGSize(width: CGFloat.random(in: -25...25), height: CGFloat.random(in: -25...25))
                flashRed.toggle()
                glitchBars = (0..<15).map { _ in CGFloat.random(in: 0...800) }
                viewScale = CGFloat.random(in: 0.95...1.05)
                
                if Int.random(in: 0...10) == 0 {
                    popups.append(BreachPopup(text: ["ACCESS DENIED", "KERNEL PANIC", "DUMP", "HALT", "OVERRIDE PENDING"].randomElement()!, position: CGPoint(x: CGFloat.random(in: 50...350), y: CGFloat.random(in: 100...700)), color: [.red, .white, .yellow].randomElement()!))
                }
                if popups.count > 12 { popups.removeFirst() }
                
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                if Int.random(in: 0...3) == 0 {
                    AudioServicesPlaySystemSound(1053) // rapid chaotic clicks
                }
            } else {
                screenShake = CGSize(width: CGFloat.random(in: -5...5), height: CGFloat.random(in: -5...5))
            }
        }
    }
    
    private func startAnimation() {
        AudioServicesPlaySystemSound(1306)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            phase = 1
            AudioServicesPlaySystemSound(1053)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            phase = 2 // Extreme Drop
            AudioServicesPlaySystemSound(1322) // Horror
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            phase = 3
            screenShake = .zero
            flashRed = false
            viewScale = 1.0
            popups.removeAll()
            AudioServicesPlaySystemSound(1307)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.8) {
            withAnimation(.easeInOut(duration: 0.8)) {
                isComplete = true
            }
        }
    }
}

struct SecretDiaryView: View {
    @Binding var isPresented: Bool
    @State private var notesText: String = UserDefaults.standard.string(forKey: "SecretVaultNotes") ?? ""
    @State private var isSpeaking = false
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var audioEngine = AVAudioEngine()
    @State private var permissionGranted = false
    
    // Unlockable Fonts System
    @State private var selectedFontName: String = "Palatino"
    
    @AppStorage("trajectoryScore") private var trajectoryScore = 0
    @AppStorage("velocityScore") private var velocityScore = 0
    @AppStorage("oscillationScore") private var oscillationScore = 0
    @AppStorage("landingScore") private var landingScore = 0
    @AppStorage("momentumScore") private var momentumScore = 0
    @AppStorage("collisionScore") private var collisionScore = 0
    @AppStorage("centripetalScore") private var centripetalScore = 0
    @AppStorage("energyScore") private var energyScore = 0
    
    private var totalGameScore: Int {
        trajectoryScore + velocityScore + oscillationScore + landingScore +
        momentumScore + collisionScore + centripetalScore + energyScore
    }
    
    struct DiaryFont: Hashable {
        let name: String
        let displayName: String
        let reqScore: Int
        let size: CGFloat
        let lineSpacing: CGFloat
        let drawSpacing: CGFloat
        let startY: CGFloat
    }
    
    private let availableFonts: [DiaryFont] = [
        DiaryFont(name: "Palatino", displayName: "Palatino", reqScore: 0, size: 22, lineSpacing: 10, drawSpacing: 36, startY: 34),
        DiaryFont(name: "Courier", displayName: "Courier", reqScore: 1000, size: 20, lineSpacing: 12, drawSpacing: 35, startY: 32),
        DiaryFont(name: "Chalkboard SE", displayName: "Chalkboard", reqScore: 3000, size: 20, lineSpacing: 10, drawSpacing: 34, startY: 32),
        DiaryFont(name: "Marker Felt", displayName: "Marker", reqScore: 6000, size: 22, lineSpacing: 8, drawSpacing: 34, startY: 32),
        DiaryFont(name: "Snell Roundhand", displayName: "Roundhand", reqScore: 10000, size: 28, lineSpacing: 6, drawSpacing: 38, startY: 38)
    ]
    
    private var activeFont: DiaryFont {
        availableFonts.first(where: { $0.name == selectedFontName }) ?? availableFonts[0]
    }
    
    var body: some View {
        ZStack {
            // Futuristic outer frame
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        withAnimation { isPresented = false }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.85))
                    }
                    Spacer()
                    Text("SECURE VAULT")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.85))
                        .tracking(2)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                
                // Font Selector Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Text("TOTAL XP: \(totalGameScore)")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                            .padding(.trailing, 8)
                        
                        ForEach(availableFonts, id: \.name) { font in
                            let isUnlocked = totalGameScore >= font.reqScore
                            Button(action: {
                                if isUnlocked { selectedFontName = font.name }
                            }) {
                                HStack(spacing: 4) {
                                    if !isUnlocked { Image(systemName: "lock.fill").font(.system(size: 10)) }
                                    Text(font.displayName)
                                }
                                .font(.custom(font.name, size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedFontName == font.name ? Color(red: 0, green: 1, blue: 0.85).opacity(0.8) : Color.white.opacity(0.1))
                                .foregroundColor(selectedFontName == font.name ? .black : (isUnlocked ? .white : .gray))
                                .cornerRadius(8)
                            }
                            .disabled(!isUnlocked)
                        }
                    }
                    .padding()
                }
                .background(Color.black)
                .overlay(Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1), alignment: .bottom)
                
                // Vintage Diary Section within tech frame
                ScrollView {
                    ZStack(alignment: .top) {
                        // Leather/Paper texture background simulation
                        Color(red: 0.96, green: 0.92, blue: 0.85) // Papyrus color
                        
                        // Vertical red margin line (like real paper)
                        HStack(spacing: 0) {
                            Rectangle().fill(Color.red.opacity(0.3)).frame(width: 1.5).padding(.leading, 50)
                            Spacer()
                        }
                        
                        // Drawn horizontal ruled lines matching the text
                        DiaryPaperLines(lineSpacing: activeFont.drawSpacing, startY: activeFont.startY)
                        
                        // Text Input
                        TextField("Begin writing...", text: $notesText, axis: .vertical)
                            .font(.custom(activeFont.name, size: activeFont.size))
                            .foregroundColor(Color.black.opacity(0.85))
                            .tint(Color.blue)
                            .lineSpacing(activeFont.lineSpacing)
                            .padding(.top, activeFont.startY - activeFont.size + 4) // adjust to sit perfectly ON the line
                            .padding(.leading, 64)
                            .padding(.trailing, 24)
                            .padding(.bottom, 200) // extra padding at bottom to scroll
                            .onChange(of: notesText) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "SecretVaultNotes")
                            }
                    }
                    .frame(minHeight: UIScreen.main.bounds.height + 200, alignment: .top)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.8), radius: 20)
                    .padding(16)
                }
                
                // Bottom Control Bar
                HStack {
                    Spacer()
                    
                    Button(action: {
                        toggleSpeech()
                    }) {
                        HStack {
                            Image(systemName: isSpeaking ? "mic.fill" : "mic.slash.fill")
                            Text(isSpeaking ? "LISTENING..." : "DICTATE")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(isSpeaking ? .black : Color(red: 0, green: 1, blue: 0.85))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(isSpeaking ? Color(red: 0, green: 1, blue: 0.85) : Color.white.opacity(0.1))
                        .cornerRadius(25)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.black)
            }
        }
        .onAppear {
            requestSpeechAuthorization()
        }
        .onDisappear {
            if isSpeaking {
                stopDictation()
            }
        }
    }
    
    // MARK: - Speech to Text Logic
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.permissionGranted = (status == .authorized)
            }
        }
    }
    
    private func toggleSpeech() {
        if isSpeaking {
            stopDictation()
        } else {
            startDictation()
        }
    }
    
    private func startDictation() {
        guard permissionGranted, let recognizer = speechRecognizer, recognizer.isAvailable else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            
            // Setup audio engine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            isSpeaking = true
            
            let initialText = notesText
            
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result = result {
                    notesText = initialText + (initialText.isEmpty ? "" : " ") + result.bestTranscription.formattedString
                    UserDefaults.standard.set(notesText, forKey: "SecretVaultNotes")
                }
                
                if error != nil || result?.isFinal == true {
                    self.stopDictation()
                }
            }
            
        } catch {
            print("Speech recognition setup failed: \(error.localizedDescription)")
            stopDictation()
        }
    }
    
    private func stopDictation() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.cancel()
        recognitionTask = nil
        isSpeaking = false
        
        // Deactivate audio session safely
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// Custom structure for drawing the ruled paper lines matched to exact font descenders
struct DiaryPaperLines: View {
    let lineSpacing: CGFloat
    let startY: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                var y: CGFloat = startY
                while y < geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += lineSpacing
                }
            }
            .stroke(Color.blue.opacity(0.25), lineWidth: 1)
        }
    }
}

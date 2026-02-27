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

// MARK: - Diary Page Data Model
struct DiaryPage: Identifiable, Codable {
    let id: UUID
    var text: String
    
    init(id: UUID = UUID(), text: String = "") {
        self.id = id
        self.text = text
    }
}

// MARK: - Diary Storage Manager
class DiaryStorageManager {
    static let shared = DiaryStorageManager()
    private let storageKey = "SecretVaultDiaryPages"
    
    func loadPages() -> [DiaryPage] {
        // Migration: if old single-note exists, convert it
        if let oldNotes = UserDefaults.standard.string(forKey: "SecretVaultNotes"), !oldNotes.isEmpty {
            let pages = [DiaryPage(text: oldNotes)]
            savePages(pages)
            UserDefaults.standard.removeObject(forKey: "SecretVaultNotes")
            return pages
        }
        
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let pages = try? JSONDecoder().decode([DiaryPage].self, from: data),
              !pages.isEmpty else {
            return [DiaryPage(text: "")]
        }
        return pages
    }
    
    func savePages(_ pages: [DiaryPage]) {
        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

// MARK: - Keyboard Dismissal Helper
struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

// MARK: - Secret Diary View (Virtual Diary with Page Turning)
struct SecretDiaryView: View {
    @Binding var isPresented: Bool
    @State private var pages: [DiaryPage] = [DiaryPage(text: "")]
    @State private var currentPageIndex: Int = 0
    @State private var isSpeaking = false
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var audioEngine = AVAudioEngine()
    @State private var permissionGranted = false
    
    // Page flip animation
    @State private var flipAngle: Double = 0
    @State private var isAnimating = false
    
    // Keyboard state
    @State private var isKeyboardVisible = false
    
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
        DiaryFont(name: "Palatino", displayName: "Palatino", reqScore: 0, size: 22, lineSpacing: 10, drawSpacing: 36, startY: 48),
        DiaryFont(name: "Courier", displayName: "Courier", reqScore: 1000, size: 20, lineSpacing: 12, drawSpacing: 35, startY: 46),
        DiaryFont(name: "Chalkboard SE", displayName: "Chalkboard", reqScore: 3000, size: 20, lineSpacing: 10, drawSpacing: 34, startY: 46),
        DiaryFont(name: "Marker Felt", displayName: "Marker", reqScore: 6000, size: 22, lineSpacing: 8, drawSpacing: 34, startY: 48),
        DiaryFont(name: "Snell Roundhand", displayName: "Roundhand", reqScore: 10000, size: 28, lineSpacing: 6, drawSpacing: 38, startY: 54)
    ]
    
    private var activeFont: DiaryFont {
        availableFonts.first(where: { $0.name == selectedFontName }) ?? availableFonts[0]
    }
    
    /// Exact top padding computed from real UIFont metrics (zero-inset UITextView)
    private var textTopPadding: CGFloat {
        let font = UIFont(name: activeFont.name, size: activeFont.size) ?? .systemFont(ofSize: activeFont.size)
        return activeFont.startY - font.ascender
    }
    
    /// Exact line-to-line spacing computed from real UIFont metrics
    private var computedDrawSpacing: CGFloat {
        let font = UIFont(name: activeFont.name, size: activeFont.size) ?? .systemFont(ofSize: activeFont.size)
        return font.lineHeight + activeFont.lineSpacing
    }
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            // Futuristic outer frame
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerBar
                
                // Font Selector Bar
                fontSelectorBar
                
                // Page indicator
                pageIndicator
                
                // Diary Page Area with page flip
                if !pages.isEmpty {
                    GeometryReader { geometry in
                        ZStack {
                            // Page underneath (revealed during flip)
                            diaryPageContent(
                                pageIndex: destinationPageIndex,
                                geometry: geometry,
                                isBackground: true
                            )
                            
                            // Current page (flips with gesture)
                            diaryPageContent(
                                pageIndex: currentPageIndex,
                                geometry: geometry,
                                isBackground: false
                            )
                            .rotation3DEffect(
                                .degrees(flipAngle),
                                axis: (x: 0, y: 1, z: 0),
                                anchor: flipAngle <= 0 ? .leading : .trailing,
                                perspective: 0.5
                            )
                            .opacity(abs(flipAngle) >= 90 ? 0 : 1)
                            .shadow(
                                color: .black.opacity(min(abs(flipAngle) / 90.0 * 0.35, 0.35)),
                                radius: 10,
                                x: flipAngle < 0 ? -5 : 5,
                                y: 0
                            )
                        }
                        .gesture(
                            DragGesture(minimumDistance: 30)
                                .onChanged { value in
                                    guard !isAnimating else { return }
                                    dismissKeyboard()
                                    let tx = value.translation.width
                                    let w = max(geometry.size.width, 1)
                                    if tx < 0 && currentPageIndex < pages.count - 1 {
                                        // Swiping left → forward flip
                                        flipAngle = max(-90, Double(tx) / Double(w) * 90)
                                    } else if tx > 0 && currentPageIndex > 0 {
                                        // Swiping right → backward flip
                                        flipAngle = min(90, Double(tx) / Double(w) * 90)
                                    } else {
                                        // At boundary, small rubber-band
                                        flipAngle = Double(tx) * 0.03
                                    }
                                }
                                .onEnded { value in
                                    guard !isAnimating else { return }
                                    if flipAngle < -25 && currentPageIndex < pages.count - 1 {
                                        completeFlipForward()
                                    } else if flipAngle > 25 && currentPageIndex > 0 {
                                        completeFlipBackward()
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                            flipAngle = 0
                                        }
                                    }
                                }
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                } else {
                    Spacer()
                }
                
                // Bottom Control Bar
                bottomBar
            }
            // Tap anywhere on the background to dismiss keyboard
            .onTapGesture {
                dismissKeyboard()
            }
        }
        .onAppear {
            requestSpeechAuthorization()
            pages = DiaryStorageManager.shared.loadPages()
            if pages.isEmpty {
                pages = [DiaryPage(text: "")]
            }
            
            // Listen for keyboard show/hide
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = false
            }
        }
        .onDisappear {
            if isSpeaking {
                stopDictation()
            }
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            Button(action: {
                dismissKeyboard()
                withAnimation { isPresented = false }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(neonCyan)
            }
            Spacer()
            Text("SECURE VAULT")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan)
                .tracking(2)
            Spacer()
            Image(systemName: "lock.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.white.opacity(0.05))
    }
    
    // MARK: - Font Selector Bar
    private var fontSelectorBar: some View {
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
                        .background(selectedFontName == font.name ? neonCyan.opacity(0.8) : Color.white.opacity(0.1))
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
    }
    
    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 12) {
            // Previous page button
            Button(action: {
                dismissKeyboard()
                if currentPageIndex > 0 {
                    turnPageBackward()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(currentPageIndex > 0 ? neonCyan : .gray.opacity(0.3))
            }
            .disabled(currentPageIndex == 0)
            
            // Page dots
            HStack(spacing: 6) {
                ForEach(pageDotsRange, id: \.self) { index in
                    Circle()
                        .fill(index == currentPageIndex ? neonCyan : Color.white.opacity(0.3))
                        .frame(width: index == currentPageIndex ? 8 : 5, height: index == currentPageIndex ? 8 : 5)
                        .scaleEffect(index == currentPageIndex ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPageIndex)
                }
            }
            
            Text("PAGE \(currentPageIndex + 1) / \(pages.count)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan.opacity(0.7))
            
            // Next page button
            Button(action: {
                dismissKeyboard()
                if currentPageIndex < pages.count - 1 {
                    turnPageForward()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(currentPageIndex < pages.count - 1 ? neonCyan : .gray.opacity(0.3))
            }
            .disabled(currentPageIndex >= pages.count - 1)
            
            Spacer()
            
            // Add new page button
            Button(action: {
                dismissKeyboard()
                addNewPage()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("NEW PAGE")
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(neonCyan)
                .cornerRadius(6)
            }
            
            // Delete page button (only if more than one page)
            if pages.count > 1 {
                Button(action: {
                    dismissKeyboard()
                    deleteCurrentPage()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black)
    }
    
    // Show at most 7 dots for pagination
    private var pageDotsRange: Range<Int> {
        let maxDots = 7
        if pages.count <= maxDots {
            return 0..<pages.count
        }
        let halfRange = maxDots / 2
        let start = max(0, min(currentPageIndex - halfRange, pages.count - maxDots))
        let end = min(pages.count, start + maxDots)
        return start..<end
    }
    
    // MARK: - Diary Page Content
    @ViewBuilder
    private func diaryPageContent(pageIndex: Int, geometry: GeometryProxy, isBackground: Bool) -> some View {
        if pages.isEmpty {
            Color.clear
        } else {
        let safeIndex = max(0, min(pageIndex, pages.count - 1))
        
        ZStack(alignment: .top) {
            // Diary cover / book edge effect
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.45, green: 0.25, blue: 0.15),
                            Color(red: 0.35, green: 0.20, blue: 0.10)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .black.opacity(0.6), radius: 8, x: 2, y: 4)
            
            // Inner page (matching ruled paper look)
            VStack(spacing: 0) {
                // Page top margin with decorative elements
                HStack {
                    // Diary hole-punch decorations
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color(red: 0.45, green: 0.25, blue: 0.15))
                            .frame(width: 10, height: 10)
                    }
                    Spacer()
                    // Date stamp area
                    Text(dateString)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.gray.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                // Ruled paper content area
                ZStack(alignment: .top) {
                    // Papyrus / aged paper color
                    Color(red: 0.96, green: 0.92, blue: 0.85)
                    
                    // Subtle paper texture noise
                    Color(red: 0.93, green: 0.89, blue: 0.82).opacity(0.3)
                    
                    // Red margin line
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.red.opacity(0.3)).frame(width: 1.5).padding(.leading, 50)
                        Spacer()
                    }
                    
                    // Ruled lines — using computed spacing from UIFont metrics
                    DiaryPaperLines(lineSpacing: computedDrawSpacing, startY: activeFont.startY)
                    
                    if !isBackground {
                        // Pixel-perfect text view (zero internal padding)
                        DiaryTextView(
                            text: Binding(
                                get: { pages[safeIndex].text },
                                set: { newValue in
                                    pages[safeIndex].text = newValue
                                    savePagesDebounced()
                                }
                            ),
                            fontName: activeFont.name,
                            fontSize: activeFont.size,
                            lineSpacing: activeFont.lineSpacing
                        )
                        .padding(.top, textTopPadding)
                        .padding(.leading, 58)
                        .padding(.trailing, 18)
                        .padding(.bottom, 20)
                    } else {
                        // Background page (non-editable preview)
                        Text(pages[safeIndex].text.isEmpty ? "Empty page..." : pages[safeIndex].text)
                            .font(.custom(activeFont.name, size: activeFont.size))
                            .foregroundColor(Color.black.opacity(0.5))
                            .lineSpacing(activeFont.lineSpacing)
                            .padding(.top, textTopPadding)
                            .padding(.leading, 58)
                            .padding(.trailing, 18)
                            .padding(.bottom, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Page number at bottom
                    VStack {
                        Spacer()
                        Text("— \(safeIndex + 1) —")
                            .font(.system(size: 12, weight: .light, design: .serif))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(6)
            .background(Color(red: 0.96, green: 0.92, blue: 0.85))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(4) // Leather border visible
            
            // Page edge (right side spine look)
            HStack {
                Spacer()
                VStack(spacing: 3) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(red: 0.90, green: 0.86, blue: 0.78))
                            .frame(width: 3, height: 4)
                    }
                }
                .padding(.trailing, 2)
                .padding(.vertical, 20)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
        } // end else (pages not empty)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: Date())
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            // Swipe hint
            if !isKeyboardVisible {
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 12))
                    Text("SWIPE TO TURN PAGE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundColor(neonCyan.opacity(0.4))
            }
            
            Spacer()
            
            Button(action: {
                dismissKeyboard()
                toggleSpeech()
            }) {
                HStack {
                    Image(systemName: isSpeaking ? "mic.fill" : "mic.slash.fill")
                    Text(isSpeaking ? "LISTENING..." : "DICTATE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .foregroundColor(isSpeaking ? .black : neonCyan)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(isSpeaking ? neonCyan : Color.white.opacity(0.1))
                .cornerRadius(25)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.black)
    }
    
    // MARK: - Page Flip Animations
    
    /// Destination page index shown underneath during flip
    private var destinationPageIndex: Int {
        if flipAngle < 0 {
            return min(currentPageIndex + 1, pages.count - 1)
        } else if flipAngle > 0 {
            return max(currentPageIndex - 1, 0)
        }
        return currentPageIndex
    }
    
    /// Flip page forward (to next page)
    private func completeFlipForward() {
        guard currentPageIndex < pages.count - 1 else { return }
        isAnimating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.4)) {
            flipAngle = -90
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            currentPageIndex += 1
            flipAngle = 0
            isAnimating = false
        }
    }
    
    /// Flip page backward (to previous page)
    private func completeFlipBackward() {
        guard currentPageIndex > 0 else { return }
        isAnimating = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.4)) {
            flipAngle = 90
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            currentPageIndex -= 1
            flipAngle = 0
            isAnimating = false
        }
    }
    
    /// Called from arrow buttons
    private func turnPageForward() {
        guard !isAnimating, currentPageIndex < pages.count - 1 else { return }
        completeFlipForward()
    }
    
    private func turnPageBackward() {
        guard !isAnimating, currentPageIndex > 0 else { return }
        completeFlipBackward()
    }
    
    private func addNewPage() {
        let newPage = DiaryPage(text: "")
        pages.insert(newPage, at: currentPageIndex + 1)
        DiaryStorageManager.shared.savePages(pages)
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            turnPageForward()
        }
    }
    
    private func deleteCurrentPage() {
        guard pages.count > 1 else { return }
        
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        isAnimating = true
        
        withAnimation(.easeOut(duration: 0.3)) {
            flipAngle = -90
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            pages.remove(at: currentPageIndex)
            if currentPageIndex >= pages.count {
                currentPageIndex = pages.count - 1
            }
            DiaryStorageManager.shared.savePages(pages)
            flipAngle = 0
            isAnimating = false
        }
    }
    
    // MARK: - Save with debounce
    @State private var saveTimer: Timer? = nil
    
    private func savePagesDebounced() {
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            DiaryStorageManager.shared.savePages(pages)
        }
    }
    
    // MARK: - Keyboard Dismissal
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            
            let safeIndex = currentPageIndex
            let initialText = pages[safeIndex].text
            
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result = result {
                    pages[safeIndex].text = initialText + (initialText.isEmpty ? "" : " ") + result.bestTranscription.formattedString
                    savePagesDebounced()
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

// MARK: - Pixel-Perfect Text View (UITextView with zero insets)
struct DiaryTextView: UIViewRepresentable {
    @Binding var text: String
    let fontName: String
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        // Zero all internal padding — text starts exactly at origin
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.backgroundColor = .clear
        tv.tintColor = .systemBlue
        tv.showsVerticalScrollIndicator = false
        tv.delegate = context.coordinator
        
        // Keyboard Done toolbar
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.doneTapped))
        ]
        toolbar.tintColor = UIColor(red: 0, green: 0.8, blue: 0.68, alpha: 1)
        tv.inputAccessoryView = toolbar
        
        applyFontStyle(tv)
        return tv
    }
    
    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != text {
            let sel = tv.selectedRange
            tv.text = text
            tv.selectedRange = sel
        }
        // Re-apply font if changed
        if context.coordinator.currentFontName != fontName {
            applyFontStyle(tv)
            context.coordinator.currentFontName = fontName
        }
    }
    
    private func applyFontStyle(_ tv: UITextView) {
        let font = UIFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
        let ps = NSMutableParagraphStyle()
        ps.lineSpacing = lineSpacing
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black.withAlphaComponent(0.85),
            .paragraphStyle: ps
        ]
        tv.typingAttributes = attrs
        if tv.text.count > 0 {
            let mutable = NSMutableAttributedString(string: tv.text, attributes: attrs)
            let sel = tv.selectedRange
            tv.attributedText = mutable
            tv.selectedRange = sel
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: DiaryTextView
        var currentFontName: String = ""
        
        init(_ parent: DiaryTextView) {
            self.parent = parent
            self.currentFontName = parent.fontName
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        @objc func doneTapped() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}

// Ruled paper lines
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

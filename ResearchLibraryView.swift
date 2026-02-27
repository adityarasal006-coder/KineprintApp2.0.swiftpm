#if os(iOS)
import SwiftUI

// MARK: - Screen State

private enum ScreenState {
    case topicPicker
    case dealing
    case showCards
}

// MARK: - Revision Screen

struct ResearchLibraryView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @Environment(\.dismiss) var dismiss
    var initialTopic: String? = nil
    
    @State private var screenState: ScreenState = .topicPicker
    @State private var selectedTopic = ""
    @State private var pickerVisible = false
    @State private var didAutoLaunch = false
    
    // Dealer animation states
    @State private var dealPhase = 0
    
    // Card feed states
    @State private var cardAppeared: Set<Int> = []
    
    // Popup
    @State private var selectedCard: RevisionCard? = nil
    @State private var popupOpen = false
    
    private let accent = Color(red: 0, green: 1, blue: 0.85)
    let flashcards: [RevisionCard] = allRevisionCards
    
    let topics: [(String, String, String)] = [
        ("MATHEMATICS", "function", "14 Concepts"),
        ("QUANTUM PHYSICS", "atom", "10 Concepts"),
        ("AI & IOT", "cpu", "10 Concepts"),
        ("MECHANICS & ENGINEERING", "gearshape.2.fill", "15 Concepts")
    ]
    
    var filteredCards: [RevisionCard] {
        flashcards.filter { $0.category == selectedTopic }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch screenState {
            case .topicPicker:
                topicPickerView
            case .dealing:
                dealerView
            case .showCards:
                cardFeedView
            }
            
            // Popup overlay
            if popupOpen, let card = selectedCard {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .onTapGesture { closePopup() }
                
                DetailCard(card: card, accent: accent, onClose: closePopup)
                    .scaleEffect(popupOpen ? 1.0 : 0.85)
                    .opacity(popupOpen ? 1.0 : 0)
                    .padding(.horizontal, 14)
            }
        }
    }
    
    // ═════════════════════════════════════
    // MARK: Phase 1 — Topic Picker
    // ═════════════════════════════════════
    
    private var topicPickerView: some View {
        VStack(spacing: 0) {
            
            Spacer()

            // Header
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.08))
                        .frame(width: 80, height: 80)
                    Circle()
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                        .frame(width: 80, height: 80)
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 32))
                        .foregroundColor(accent)
                }
                .opacity(pickerVisible ? 1 : 0)
                .scaleEffect(pickerVisible ? 1 : 0.7)
                
                Text("SELECT YOUR\nREVISION TOPIC")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(pickerVisible ? 1 : 0)
                
                Text("CHOOSE A DOMAIN TO BEGIN")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(accent.opacity(0.4))
                    .opacity(pickerVisible ? 1 : 0)
            }
            .padding(.bottom, 36)
            
            // Topic Buttons
            VStack(spacing: 10) {
                ForEach(Array(topics.enumerated()), id: \.offset) { idx, topic in
                    Button(action: { pickTopic(topic.0) }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accent.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(accent.opacity(0.3), lineWidth: 1)
                                    )
                                Image(systemName: topic.1)
                                    .font(.system(size: 18))
                                    .foregroundColor(accent)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(topic.0)
                                    .font(.system(size: 13, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Text(topic.2)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(accent.opacity(0.4))
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(accent.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(accent.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PressStyle())
                    .opacity(pickerVisible ? 1 : 0)
                    .offset(y: pickerVisible ? 0 : CGFloat(15 + idx * 5))
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .onAppear {
            // Auto-launch if initialTopic is set
            if let topic = initialTopic, !didAutoLaunch {
                didAutoLaunch = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    pickTopic(topic)
                }
            } else {
                withAnimation(.easeOut(duration: 0.6)) {
                    pickerVisible = true
                }
            }
        }
    }
    
    // ═════════════════════════════════════
    // MARK: Phase 2 — Dealer Animation
    // ═════════════════════════════════════
    
    private var dealerView: some View {
        ZStack {
            // Title at top
            VStack {
                Text("DEALING \(selectedTopic)...")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(accent.opacity(dealPhase < 4 ? 0.7 : 0))
                    .padding(.top, 80)
                Spacer()
            }
            
            // Card deck
            ForEach(0..<6, id: \.self) { i in
                cardShape(index: i)
            }
        }
        .onAppear { runDealSequence() }
    }
    
    private func cardShape(index i: Int) -> some View {
        let di = Double(i)
        let total = 6.0
        
        // Phase 0: stacked in center
        // Phase 1: fan out (rotate)
        // Phase 2: spread horizontally
        // Phase 3: cascade down
        // Phase 4: fade out
        
        let rotation: Double = {
            if dealPhase >= 1 && dealPhase < 3 {
                return (di - total / 2.0) * 12
            }
            return 0
        }()
        
        let xOff: CGFloat = {
            if dealPhase == 2 {
                return CGFloat(di - total / 2.0) * 40
            }
            return 0
        }()
        
        let yOff: CGFloat = {
            if dealPhase == 0 { return CGFloat(i) * -3 }
            if dealPhase == 1 { return CGFloat(i) * -6 }
            if dealPhase == 2 { return CGFloat(i) * -4 }
            if dealPhase == 3 { return CGFloat(i) * 60 - 100 }
            return 0
        }()
        
        let scale: CGFloat = {
            if dealPhase == 2 { return 0.85 }
            if dealPhase >= 4 { return 0.6 }
            return 1.0
        }()
        
        let opacity: Double = dealPhase >= 4 ? 0 : 1
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [accent.opacity(0.15), accent.opacity(0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .frame(width: 160, height: 220)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accent.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 22))
                        .foregroundColor(accent.opacity(0.5))
                    Text(String(selectedTopic.prefix(4)).uppercased())
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(accent.opacity(0.3))
                }
            )
            .rotationEffect(.degrees(rotation))
            .offset(x: xOff, y: yOff)
            .scaleEffect(scale)
            .opacity(opacity)
    }
    
    // ═════════════════════════════════════
    // MARK: Phase 3 — Card Feed
    // ═════════════════════════════════════
    
    private var cardFeedView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: goBack) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("TOPICS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(accent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(selectedTopic)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text("\(filteredCards.count) CARDS READY")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(accent.opacity(0.5))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Cards
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(Array(filteredCards.enumerated()), id: \.element.id) { index, card in
                        FlashCard(card: card, accent: accent, onTap: {
                            selectedCard = card
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                popupOpen = true
                            }
                        })
                        .opacity(cardAppeared.contains(index) ? 1 : 0)
                        .offset(y: cardAppeared.contains(index) ? 0 : 40)
                        .onAppear {
                            let delay = Double(index) * 0.1
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                let _ = withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                    cardAppeared.insert(index)
                                }
                                if index < 5 {
                                    let tick = UIImpactFeedbackGenerator(style: .light)
                                    tick.impactOccurred()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .allowsHitTesting(!popupOpen)
            .opacity(popupOpen ? 0.2 : 1.0)
        }
    }
    
    // ═════════════════════════════════════
    // MARK: Actions
    // ═════════════════════════════════════
    
    private func pickTopic(_ topic: String) {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()
        selectedTopic = topic
        dealPhase = 0
        cardAppeared = []
        withAnimation(.easeInOut(duration: 0.2)) {
            screenState = .dealing
        }
    }
    
    private func runDealSequence() {
        // Phase 1: Fan out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { dealPhase = 1 }
        }
        // Phase 2: Spread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { dealPhase = 2 }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        // Phase 3: Cascade
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { dealPhase = 3 }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        // Phase 4: Fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeIn(duration: 0.25)) { dealPhase = 4 }
        }
        // Show cards
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                screenState = .showCards
            }
        }
    }
    
    private func goBack() {
        if initialTopic != nil {
            dismiss()
        } else {
            pickerVisible = false
            cardAppeared = []
            withAnimation(.easeInOut(duration: 0.25)) {
                screenState = .topicPicker
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    pickerVisible = true
                }
            }
        }
    }
    
    private func closePopup() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            popupOpen = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            selectedCard = nil
        }
    }
}

// MARK: - Press Style
private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Flash Card (in Feed)

private struct FlashCard: View {
    let card: RevisionCard
    let accent: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 5) {
                        Circle().fill(accent).frame(width: 6, height: 6)
                        Text(card.code)
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(accent)
                    }
                    Spacer()
                    Image(systemName: card.icon)
                        .font(.system(size: 16))
                        .foregroundColor(accent.opacity(0.5))
                }
                
                Text(card.title.uppercased())
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(card.formula)
                    .font(.system(size: 16, weight: .heavy, design: .serif))
                    .foregroundColor(accent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(accent.opacity(0.06))
                    )
                
                Text(card.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    Spacer()
                    Text("TAP TO EXPLORE ▸")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(accent.opacity(0.4))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.06, green: 0.06, blue: 0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accent.opacity(0.15), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - Detail Card (Popup)

private struct DetailCard: View {
    let card: RevisionCard
    let accent: Color
    let onClose: () -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(card.code, systemImage: card.icon)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(accent)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Text(card.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(card.formula)
                    .font(.system(size: 18, weight: .heavy, design: .serif))
                    .foregroundColor(accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accent.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(accent.opacity(0.2), lineWidth: 1)
                            )
                    )
                
                Text(card.category)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(accent)
                    .cornerRadius(6)
                
                Text(card.subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accent.opacity(0.7))
                    .italic()
                
                Text(card.deepElaboration)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Concept display
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: card.icon)
                            .font(.system(size: 44))
                            .foregroundColor(accent.opacity(0.5))
                        Text(card.code)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(accent.opacity(0.4))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(accent.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(accent.opacity(0.1), lineWidth: 1)
                            )
                    )
                    Spacer()
                }
                
                // Real-world example
                VStack(alignment: .leading, spacing: 10) {
                    Label("REAL-WORLD EXAMPLE", systemImage: "lightbulb.fill")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.orange)
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.08))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                )
                            Image(systemName: card.examplePictogram)
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                        }
                        Text(card.exampleText)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.12), lineWidth: 1)
                )
                
                HStack(spacing: 8) {
                    Image(systemName: "function")
                        .foregroundColor(accent.opacity(0.5))
                        .font(.system(size: 12))
                    Text(card.formula)
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(22)
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.82)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(red: 0.05, green: 0.05, blue: 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(accent.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.5), radius: 20)
    }
}

#endif

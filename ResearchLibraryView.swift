#if os(iOS)
import SwiftUI

struct ResearchLibraryView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: ResearchTab = .images
    @State private var showingPaperComposer = false
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    enum ResearchTab: String, CaseIterable {
        case images = "SCANS & BLUEPRINTS"
        case papers = "PUBLICATIONS"
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(neonCyan)
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    Spacer()
                    
                    Text("RESEARCH ARCHIVE")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                    
                    Spacer()
                    
                    Button(action: {
                        if selectedTab == .papers {
                            showingPaperComposer = true
                        }
                    }) {
                        Image(systemName: selectedTab == .papers ? "plus.rectangle.fill.on.rectangle.fill" : "folder.fill.badge.plus")
                            .foregroundColor(selectedTab == .papers ? neonCyan : neonCyan.opacity(0.3))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.9))
                
                Rectangle()
                    .fill(neonCyan.opacity(0.3))
                    .frame(height: 1)
                
                // Custom Tab Picker
                HStack(spacing: 0) {
                    ForEach(ResearchTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(selectedTab == tab ? neonCyan : .gray)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(selectedTab == tab ? neonCyan.opacity(0.1) : Color.clear)
                                .overlay(
                                    Rectangle()
                                        .fill(selectedTab == tab ? neonCyan : Color.clear)
                                        .frame(height: 2),
                                    alignment: .bottom
                                )
                        }
                    }
                }
                
                if selectedTab == .images {
                    if viewModel.researchEntries.isEmpty {
                        EmptyResearchState(
                            icon: "doc.text.magnifyingglass",
                            title: "NO DATA LOGGED",
                            subtitle: "Use the AR Scanner's 'DEEP SCAN' or Camera to analyze physical objects and build your archive."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.researchEntries.reversed()) { entry in
                                    ResearchEntryCard(entry: entry, onClone: {
                                        viewModel.cloneEntry(entry)
                                    })
                                }
                            }
                            .padding(16)
                        }
                    }
                } else {
                    if viewModel.publishedPapers.isEmpty {
                        EmptyResearchState(
                            icon: "scroll",
                            title: "NO PUBLICATIONS",
                            subtitle: "Write and publish whitepapers summarizing your kinematic research and findings."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.publishedPapers.reversed()) { paper in
                                    PaperEntryCard(paper: paper)
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaperComposer) {
            PaperComposerView(viewModel: viewModel)
        }
    }
}

struct EmptyResearchState: View {
    let icon: String
    let title: String
    let subtitle: String
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(neonCyan.opacity(0.2))
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(subtitle)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
}

struct ResearchEntryCard: View {
    let entry: ResearchEntry
    var onClone: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Button(action: onClone) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("CLONE")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(neonCyan)
                    .cornerRadius(6)
                }
            }
            .padding(14)
            .background(neonCyan.opacity(0.05))
            
            HStack(spacing: 16) {
                // Blueprint small preview
                ZStack {
                    Rectangle()
                        .stroke(neonCyan.opacity(0.2), lineWidth: 1)
                    Image(systemName: "wand.and.stars.inverse")
                        .foregroundColor(neonCyan.opacity(0.4))
                }
                .frame(width: 80, height: 80)
                .background(Color.black.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        DetailBadge(label: "DIM", value: entry.dimensions)
                        DetailBadge(label: "MASS", value: entry.mass)
                    }
                    HStack {
                        DetailBadge(label: "MAT", value: entry.material)
                        DetailBadge(label: "QUAL", value: entry.scanQuality)
                    }
                }
            }
            .padding(14)
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(neonCyan.opacity(0.15), lineWidth: 1)
        )
    }
}

struct DetailBadge: View {
    let label: String
    let value: String
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.4))
        .cornerRadius(4)
    }
}

// MARK: - Paper View

struct PaperEntryCard: View {
    let paper: ResearchPaper
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(paper.title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "scroll.fill")
                    .foregroundColor(neonCyan.opacity(0.7))
            }
            
            Text(paper.content)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(paper.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Text("AUTHOR: OPERATOR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(neonCyan.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PaperComposerView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var content = ""
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button("CANCEL") { dismiss() }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                    Spacer()
                    Text("NEW PUBLICATION")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Button("PUBLISH") {
                        if !title.isEmpty && !content.isEmpty {
                            viewModel.publishPaper(title: title, content: content)
                            dismiss()
                        }
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(title.isEmpty || content.isEmpty ? .gray : neonCyan)
                    .disabled(title.isEmpty || content.isEmpty)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                
                VStack(spacing: 1) {
                    TextField("Enter Document Title...", text: $title)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .padding()
                        .background(Color.white.opacity(0.02))
                    
                    TextEditor(text: $content)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.01))
                        .padding()
                }
            }
        }
    }
}
#endif

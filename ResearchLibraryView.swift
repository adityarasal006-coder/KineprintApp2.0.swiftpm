#if os(iOS)
import SwiftUI

@available(iOS 16.0, *)
struct ResearchLibraryView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @Environment(\.dismiss) var dismiss
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
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
                    
                    Image(systemName: "folder.fill.badge.plus")
                        .foregroundColor(neonCyan.opacity(0.3))
                }
                .padding()
                .background(Color.black.opacity(0.9))
                
                Rectangle()
                    .fill(neonCyan.opacity(0.3))
                    .frame(height: 1)
                
                if viewModel.researchEntries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(neonCyan.opacity(0.2))
                        Text("NO DATA LOGGED")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("Use the AR Scanner's 'DEEP SCAN' feature to analyze physical objects and build your archive.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxHeight: .infinity)
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
            }
        }
    }
}

@available(iOS 16.0, *)
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

@available(iOS 16.0, *)
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
#endif

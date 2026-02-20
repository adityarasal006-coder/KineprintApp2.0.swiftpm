import SwiftUI

#if !os(iOS)
// macOS fallback placeholder — the real KineprintView is in ContentView.swift (iOS only)
@available(macOS 12.0, *)
struct KineprintView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg")
                .imageScale(.large)
                .font(.system(size: 48, weight: .semibold))
            Text("Kineprint")
                .font(.largeTitle).bold()
            Text("Kineprint requires an iOS device with ARKit support.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
#endif

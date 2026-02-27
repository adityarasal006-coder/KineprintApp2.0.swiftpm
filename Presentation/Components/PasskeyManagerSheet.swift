import SwiftUI

public struct PasskeyManagerSheet: View {
    @Binding public var isPresented: Bool
    @State private var currentPasskey = UserDefaults.standard.string(forKey: "SecretVaultPasskey") ?? ""
    @State private var newPasskey = ""
    @State private var message = ""
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Text("SECURE VAULT ACCESS")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(neonCyan)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                
                Text("Manage your numeric bypass code for the Scientific Calculator.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CURRENT PASSKEY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(currentPasskey.isEmpty ? "NOT SET" : currentPasskey)
                            .font(.system(size: 24, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NEW PASSKEY")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        TextField("Enter new numbers...", text: $newPasskey)
                            .keyboardType(.numberPad)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                            .padding()
                            .background(Color.black)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.5), lineWidth: 1))
                    }
                    
                    if !message.isEmpty {
                        Text(message)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                
                Button(action: saveNewPasskey) {
                    Text("UPDATE IDENTIFIER")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(neonCyan)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(24)
            .padding(.top, 20)
        }
    }
    
    private func saveNewPasskey() {
        guard !newPasskey.isEmpty && newPasskey.allSatisfy({ $0.isNumber }) else {
            message = "Passkey must be numeric."
            return
        }
        UserDefaults.standard.set(newPasskey, forKey: "SecretVaultPasskey")
        currentPasskey = newPasskey
        newPasskey = ""
        message = "Passkey updated successfully ✓"
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

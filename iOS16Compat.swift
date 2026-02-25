import SwiftUI
import Combine

extension View {
    @ViewBuilder
    func legacyOnChange<T: Equatable>(of value: T, perform action: @escaping (T) -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.modifier(ChangeObserverModifier(value: value, action: action))
        }
    }
}

private struct ChangeObserverModifier<T: Equatable>: ViewModifier {
    let value: T
    let action: (T) -> Void
    
    @State private var oldValue: T
    
    init(value: T, action: @escaping (T) -> Void) {
        self.value = value
        self.action = action
        self._oldValue = State(initialValue: value)
    }
    
    func body(content: Content) -> some View {
        content
            .onReceive(Just(value)) { newValue in
                if newValue != oldValue {
                    action(newValue)
                    oldValue = newValue
                }
            }
    }
}

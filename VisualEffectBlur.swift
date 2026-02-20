import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

#if canImport(UIKit)
import SwiftUI
import UIKit

struct VisualEffectBlur<Content: View>: View {
    private var blurStyle: UIBlurEffect.Style
    private var content: Content
    
    init(blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial, @ViewBuilder content: () -> Content) {
        self.blurStyle = blurStyle
        self.content = content()
    }
    
    var body: some View {
        Representable(blurStyle: blurStyle, content: content)
    }
}

extension VisualEffectBlur {
    private struct Representable<ContentFromOuterScope: View>: UIViewRepresentable {
        var blurStyle: UIBlurEffect.Style
        var content: ContentFromOuterScope
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            context.coordinator.blurView
        }
        
        func updateUIView(_ view: UIVisualEffectView, context: Context) {
            context.coordinator.update(content: content, blurStyle: blurStyle)
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(content: content)
        }
        
        @MainActor
        class Coordinator: NSObject {
            let blurView = UIVisualEffectView()
            let hostingController: UIHostingController<ContentFromOuterScope>
            
            @MainActor
            init(content: ContentFromOuterScope) {
                self.hostingController = UIHostingController(rootView: content)
                super.init()
                
                setupViews()
            }
            
            @MainActor func setupViews() {
                blurView.contentView.addSubview(hostingController.view)
                
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostingController.view.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
                    hostingController.view.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
                    hostingController.view.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
                    hostingController.view.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
                ])
            }
            
            @MainActor func update(content: ContentFromOuterScope, blurStyle: UIBlurEffect.Style) {
                hostingController.rootView = content
                
                let blurEffect = UIBlurEffect(style: blurStyle)
                blurView.effect = blurEffect
            }
        }
    }
}
#endif

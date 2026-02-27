import SwiftUI
import SceneKit

// MARK: - 3D Avatar View (Pure Geometry Engine)
// MARK: - 3D Avatar View (Pure Geometry Engine)
public struct Avatar3DView: UIViewRepresentable {
    public let avatarType: CoreShape
    public let avatarColor: Color
    public let isExpanded: Bool
    
    public init(avatarType: CoreShape, avatarColor: Color, isExpanded: Bool = false) {
        self.avatarType = avatarType
        self.avatarColor = avatarColor
        self.isExpanded = isExpanded
    }
    
    public func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear 
        scnView.allowsCameraControl = isExpanded
        scnView.autoenablesDefaultLighting = false
        scnView.showsStatistics = false
        scnView.antialiasingMode = .multisampling4X
        scnView.scene = createScene()
        return scnView
    }
    
    public func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.scene = createScene()
        scnView.allowsCameraControl = isExpanded
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Complex particle/star system in background for 3D depth
        let stars = SCNParticleSystem()
        stars.birthRate = 100
        stars.particleLifeSpan = 10
        stars.particleColor = .white
        stars.particleSize = 0.05
        stars.emitterShape = SCNSphere(radius: 10)
        stars.particleVelocity = 0.1
        stars.blendMode = .additive
        
        let particleNode = SCNNode()
        particleNode.addParticleSystem(stars)
        scene.rootNode.addChildNode(particleNode)
        
        let coreNode = QuantumCoreBuilder.build(type: avatarType, color: avatarColor)
        coreNode.position = SCNVector3(x: 0, y: isExpanded ? -0.5 : -0.5, z: 0)
        scene.rootNode.addChildNode(coreNode)
        
        // --- High-End Cinematic Lighting ---
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 500
        ambient.color = UIColor.white
        let ambNode = SCNNode()
        ambNode.light = ambient
        scene.rootNode.addChildNode(ambNode)
        
        let keyLight = SCNLight()
        keyLight.type = .spot
        keyLight.intensity = 3000
        keyLight.castsShadow = true
        keyLight.shadowMode = .deferred
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.8)
        keyLight.color = UIColor.white
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(-5, 10, 10)
        keyNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        scene.rootNode.addChildNode(keyNode)
        
        let rimLight = SCNLight()
        rimLight.type = .omni
        rimLight.intensity = 2500
        rimLight.color = UIColor(avatarColor)
        let rimNode = SCNNode()
        rimNode.light = rimLight
        rimNode.position = SCNVector3(0, 5, -10)
        scene.rootNode.addChildNode(rimNode)
        
        // Intense glow light center
        let coreLight = SCNLight()
        coreLight.type = .omni
        coreLight.intensity = 1500
        coreLight.color = UIColor(avatarColor)
        let coreLightNode = SCNNode()
        coreLightNode.light = coreLight
        coreLightNode.position = SCNVector3(0, isExpanded ? -0.5 : -0.5, 0)
        scene.rootNode.addChildNode(coreLightNode)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // Adding depth of field to camera
        cameraNode.camera?.wantsDepthOfField = true
        cameraNode.camera?.focusDistance = isExpanded ? 4 : 5
        cameraNode.camera?.fStop = 1.4
        cameraNode.position = SCNVector3(x: 0, y: isExpanded ? 0 : 0, z: isExpanded ? 4 : 5)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }
}

// MARK: - Quantum Core Builder Engine
struct QuantumCoreBuilder {
    static func build(type: CoreShape, color: Color) -> SCNNode {
        let root = SCNNode()
        let primaryColor = UIColor(color)
        
        let glassMat = SCNMaterial()
        glassMat.lightingModel = .physicallyBased
        glassMat.diffuse.contents = UIColor(white: 1.0, alpha: 0.05)
        glassMat.metalness.contents = 1.0
        glassMat.roughness.contents = 0.0
        glassMat.transparent.contents = UIColor(white: 1.0, alpha: 0.3)
        glassMat.isDoubleSided = true
        
        let energyMat = SCNMaterial()
        energyMat.lightingModel = .constant
        energyMat.diffuse.contents = primaryColor
        energyMat.emission.contents = primaryColor
        
        let solidMat = SCNMaterial()
        solidMat.lightingModel = .physicallyBased
        solidMat.diffuse.contents = primaryColor
        solidMat.metalness.contents = 0.9
        solidMat.roughness.contents = 0.1

        let wireframeMat = SCNMaterial()
        wireframeMat.lightingModel = .constant
        wireframeMat.diffuse.contents = primaryColor
        wireframeMat.emission.contents = primaryColor
        wireframeMat.fillMode = .lines
        
        switch type {
        case .sphere, .robot1, .scout:
            let outer = SCNNode(geometry: SCNSphere(radius: 1.2))
            outer.geometry?.materials = [glassMat]
            let inner = SCNNode(geometry: SCNSphere(radius: 0.6))
            inner.geometry?.materials = [energyMat]
            let wire = SCNNode(geometry: SCNSphere(radius: 1.3))
            wire.geometry?.materials = [wireframeMat]
            
            root.addChildNode(outer)
            root.addChildNode(inner)
            root.addChildNode(wire)
            
            // Orbiting satellites
            for i in 0..<3 {
                let sat = SCNNode(geometry: SCNSphere(radius: 0.1))
                sat.geometry?.materials = [solidMat]
                sat.position = SCNVector3(1.6, 0, 0)
                let pivot = SCNNode()
                pivot.eulerAngles = SCNVector3(CGFloat.random(in: 0...6), CGFloat.random(in: 0...6), 0)
                pivot.addChildNode(sat)
                root.addChildNode(pivot)
                pivot.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 3.0 + Double(i), z: 0, duration: 2.0)))
            }
            
            inner.runAction(SCNAction.repeatForever(SCNAction.sequence([
                SCNAction.scale(to: 1.3, duration: 1.5),
                SCNAction.scale(to: 1.0, duration: 1.5)
            ])))
            wire.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 1.5, z: 0.5, duration: 4.0)))

        case .tetrahedron, .robot2, .warrior: // Merkaba (Star Tetrahedron)
            let pyr = SCNPyramid(width: 1.8, height: 1.8, length: 1.8)
            let node1 = SCNNode(geometry: pyr)
            node1.geometry?.materials = [solidMat]
            node1.position = SCNVector3(0, -0.9, 0)
            
            let node2 = SCNNode(geometry: pyr)
            node2.geometry?.materials = [solidMat]
            node2.position = SCNVector3(0, 0.9, 0)
            node2.eulerAngles = SCNVector3(CGFloat.pi, 0, 0)
            
            let merkaba = SCNNode()
            merkaba.addChildNode(node1)
            merkaba.addChildNode(node2)
            
            let wire = SCNNode(geometry: SCNSphere(radius: 1.6))
            wire.geometry?.materials = [wireframeMat]
            
            root.addChildNode(merkaba)
            root.addChildNode(wire)
            
            merkaba.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: CGFloat.pi * 2, z: 0.5, duration: 4.0)))
            wire.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: -0.5, y: -1, z: -0.5, duration: 5.0)))
            
        case .torus, .robot3, .titan: // Intersecting rings
            for i in 0..<3 {
                let ring = SCNNode(geometry: SCNTorus(ringRadius: 1.2, pipeRadius: 0.15))
                ring.geometry?.materials = [i == 1 ? energyMat : solidMat]
                ring.eulerAngles = SCNVector3(CGFloat(i) * (.pi/3), CGFloat(i) * (.pi/4), 0)
                root.addChildNode(ring)
                let speed = Double(i + 1) * 1.5
                ring.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: speed/2, y: speed, z: speed/3, duration: 4.0)))
            }
            let core = SCNNode(geometry: SCNSphere(radius: 0.4))
            core.geometry?.materials = [energyMat]
            root.addChildNode(core)
            core.runAction(SCNAction.repeatForever(SCNAction.sequence([
                SCNAction.scale(to: 1.5, duration: 1.0),
                SCNAction.scale(to: 1.0, duration: 1.0)
            ])))
            
        case .helix, .robot4, .core: // Advanced DNA
            let centerCyl = SCNNode(geometry: SCNCylinder(radius: 0.3, height: 3.0))
            centerCyl.geometry?.materials = [glassMat]
            root.addChildNode(centerCyl)
            
            for i in 0..<16 {
                let p = SCNNode(geometry: SCNSphere(radius: 0.15))
                p.geometry?.materials = [energyMat]
                let angle = CGFloat(i) * 0.5
                let y = CGFloat(i) * 0.2 - 1.5
                p.position = SCNVector3(sin(angle)*1.2, y, cos(angle)*1.2)
                root.addChildNode(p)
                
                let p2 = SCNNode(geometry: SCNSphere(radius: 0.15))
                p2.geometry?.materials = [solidMat]
                p2.position = SCNVector3(sin(angle + .pi)*1.2, y, cos(angle + .pi)*1.2)
                root.addChildNode(p2)
                
                // Connection bar
                let bar = SCNNode(geometry: SCNCylinder(radius: 0.02, height: 2.4))
                bar.geometry?.materials = [wireframeMat]
                bar.position = SCNVector3(0, y, 0)
                bar.eulerAngles = SCNVector3(CGFloat.pi/2, 0, -angle)
                root.addChildNode(bar)
            }
            root.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 4.0)))

        case .icosahedron, .drone, .spark: // Floating shards
            let icosaGeo = SCNSphere(radius: 1.0)
            icosaGeo.segmentCount = 4
            icosaGeo.materials = [glassMat]
            let icosa = SCNNode(geometry: icosaGeo)
            root.addChildNode(icosa)
            
            let innerGeo = SCNSphere(radius: 0.5)
            innerGeo.segmentCount = 4
            innerGeo.materials = [energyMat]
            let inner = SCNNode(geometry: innerGeo)
            root.addChildNode(inner)
            
            for _ in 0..<8 {
                let shardGeo = SCNPyramid(width: 0.3, height: 0.5, length: 0.3)
                shardGeo.materials = [solidMat]
                let shard = SCNNode(geometry: shardGeo)
                let dist: Float = 1.8
                let theta = Float.random(in: 0...(.pi*2))
                let phi = Float.random(in: 0...(.pi))
                shard.position = SCNVector3(dist * sin(phi) * cos(theta), dist * cos(phi), dist * sin(phi) * sin(theta))
                shard.look(at: SCNVector3(0,0,0))
                
                let pivot = SCNNode()
                pivot.addChildNode(shard)
                root.addChildNode(pivot)
                pivot.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: -2...2), z: CGFloat.random(in: -1...1), duration: 4.0)))
            }
            
            inner.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: -1, y: -1.5, z: -1, duration: 3.0)))

        case .box, .android, .nexus: // Tesseract
            for i in 0..<3 {
                let size = 1.6 - CGFloat(i) * 0.4
                let box = SCNNode(geometry: SCNBox(width: size, height: size, length: size, chamferRadius: 0.05))
                if i == 0 {
                    box.geometry?.materials = [glassMat]
                } else if i == 1 {
                    box.geometry?.materials = [wireframeMat]
                } else {
                    box.geometry?.materials = [energyMat]
                }
                
                let pivot = SCNNode()
                pivot.addChildNode(box)
                root.addChildNode(pivot)
                
                let speed = 1.0 + Double(i) * 0.5
                let dir: CGFloat = i % 2 == 0 ? 1 : -1
                pivot.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0.5 * dir, y: 1.0 * dir, z: 0.5 * dir, duration: 4.0 / speed)))
            }
        }
        
        // Universal Bobbing Motion
        let floatUp = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 2.5)
        floatUp.timingMode = .easeInEaseOut
        let seq = SCNAction.sequence([floatUp, floatUp.reversed()])
        root.runAction(SCNAction.repeatForever(seq))
        
        return root
    }
}

// MARK: - Avatar SwiftUI Background Views
public struct AvatarBackgroundEngine: View {
    public let theme: AvatarBackgroundTheme
    public let color: Color
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch theme {
            case .eventHorizon:
                EventHorizonBackground(color: color)
            case .nebulaVoid:
                NebulaVoidBackground(color: color)
            case .quantumFoam:
                QuantumFoamBackground(color: color)
            case .hyperspace:
                HyperspaceBackground(color: color)
            case .deepCosmos:
                DeepCosmosBackground(color: color)
            }
        }
        .ignoresSafeArea()
    }
}

struct EventHorizonBackground: View {
    let color: Color
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Accretion Disk
            Circle()
                .fill(
                    AngularGradient(gradient: Gradient(colors: [color.opacity(0.8), .black, color.opacity(0.4), .black, color.opacity(0.8)]), center: .center)
                )
                .frame(width: 400, height: 400)
                .rotationEffect(.degrees(rotation))
                .blur(radius: 20)
                .scaleEffect(CGSize(width: 1.0, height: 0.3))
                .rotationEffect(.degrees(-20))
            
            // Lensing
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 4)
                .frame(width: 250, height: 250)
                .shadow(color: color, radius: 20)
                .blur(radius: 5)
            
            // Black Hole center
            Circle()
                .fill(Color.black)
                .frame(width: 240, height: 240)
            
            // Hawking Radiation
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 240, height: 240)
                .scaleEffect(pulse)
                .opacity(2.0 - pulse)
                .blur(radius: 10)
        }
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeOut(duration: 3).repeatForever(autoreverses: false)) {
                pulse = 1.5
            }
        }
    }
}

struct NebulaVoidBackground: View {
    let color: Color
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [color.opacity(0.2), .black]), center: .center, startRadius: 50, endRadius: 400)
            
            ForEach(0..<4) { i in
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: CGFloat.random(in: 150...300), height: CGFloat.random(in: 150...300))
                    .blur(radius: CGFloat.random(in: 30...60))
                    .offset(x: sin(phase + CGFloat(i)) * 100, y: cos(phase + CGFloat(i) * 0.5) * 100)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct QuantumFoamBackground: View {
    let color: Color
    @State private var isAnimating = false
    
    struct Bubble: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
    }
    
    let bubbles = (0..<40).map { _ in
        Bubble(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
            size: CGFloat.random(in: 10...60),
            delay: Double.random(in: 0...3)
        )
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            ForEach(bubbles) { b in
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: b.size, height: b.size)
                    .position(x: b.x, y: b.y)
                    .scaleEffect(isAnimating ? 1.5 : 0.1)
                    .opacity(isAnimating ? 0 : 1)
                    .blur(radius: isAnimating ? 4 : 0)
                    .animation(
                        Animation.easeOut(duration: 2.5).repeatForever(autoreverses: false).delay(b.delay),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct HyperspaceBackground: View {
    let color: Color
    @State private var isAnimating = false
    
    struct StarLine: Identifiable {
        let id = UUID()
        let angle: Double
        let length: CGFloat
    }
    
    let lines = (0..<100).map { _ in
        StarLine(
            angle: Double.random(in: 0...360),
            length: CGFloat.random(in: 20...150)
        )
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                
                ForEach(lines) { star in
                    Rectangle()
                        .fill(LinearGradient(colors: [color, .white], startPoint: .leading, endPoint: .trailing))
                        .frame(width: star.length, height: 2)
                        .offset(x: isAnimating ? geo.size.width : 20)
                        .rotationEffect(.degrees(star.angle))
                        .position(center)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(
                            Animation.easeIn(duration: Double.random(in: 0.5...1.5)).repeatForever(autoreverses: false).delay(Double.random(in: 0...1)),
                            value: isAnimating
                        )
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct DeepCosmosBackground: View {
    let color: Color
    
    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }
    
    let stars = (0..<150).map { _ in
        Star(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
            size: CGFloat.random(in: 1...3),
            opacity: Double.random(in: 0.2...1.0)
        )
    }
    
    @State private var twinkle = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, color.opacity(0.1)], startPoint: .top, endPoint: .bottom)
            
            ForEach(stars) { s in
                Circle()
                    .fill(Color.white)
                    .frame(width: s.size, height: s.size)
                    .position(x: s.x, y: s.y)
                    .opacity(twinkle ? s.opacity : s.opacity * 0.3)
                    .blur(radius: s.size > 2 ? 1 : 0)
                    .animation(Animation.easeInOut(duration: Double.random(in: 1...3)).repeatForever(autoreverses: true), value: twinkle)
            }
        }
        .onAppear {
            twinkle = true
        }
    }
}

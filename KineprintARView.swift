#if os(iOS)
import Foundation
import ARKit
import SceneKit
import SwiftUI
import UIKit

/// The core AR view that renders the Blueprint-style diagnostic overlay.
/// Features: LiDAR mesh wireframe, 3D grid, velocity/acceleration vectors with arrowheads,
/// trajectory ghosting with opacity fade, and neon bloom glow effect.
@available(iOS 16.0, *)
class KineprintARView: UIView, @preconcurrency ARSCNViewDelegate, @preconcurrency ARSessionDelegate {
    var arSCNView: ARSCNView!
    var arSession: ARSession!
    var trackedObjects: [UUID: TrackedObject] = [:]
    var trajectoryPoints: [SIMD3<Float>] = []
    var currentTrajectoryNode: SCNNode?
    private let physicsEngine = PhysicsEngine.shared
    
    // Neon cyan color used throughout
    private let neonCyan = UIColor(red: 0, green: 1, blue: 0.85, alpha: 1.0)
    private let neonCyanDim = UIColor(red: 0, green: 1, blue: 0.85, alpha: 0.3)
    private let velocityRed = UIColor(red: 1.0, green: 0.2, blue: 0.3, alpha: 1.0)
    private let accelBlue = UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)
    
    // State toggles from UI
    var showVectors: Bool = true
    var recordingPath: Bool = false
    
    // Callback to send tracking data back to ViewModel
    var onTrackingUpdate: ((SIMD3<Float>, SIMD3<Float>, SIMD3<Float>) -> Void)?
    
    // Grid nodes for cleanup
    private var gridNodes: [SCNNode] = []
    private var meshOverlayNodes: [UUID: SCNNode] = [:]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupARView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupARView()
    }
    
    private func setupARView() {
        arSCNView = ARSCNView(frame: bounds)
        arSCNView.delegate = self
        arSCNView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arSCNView.antialiasingMode = .none
        arSCNView.autoenablesDefaultLighting = false
        arSCNView.preferredFramesPerSecond = 60
        arSCNView.isPlaying = true
        arSCNView.rendersContinuously = true
        
        // Dark background for Blueprint aesthetic
        arSCNView.scene.background.contents = UIColor.black
        
        addSubview(arSCNView)
        
        // Set up scene with subtle ambient lighting
        let scene = SCNScene()
        arSCNView.scene = scene
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.light!.color = UIColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // Apply bloom post-processing for neon glow
        applyBloomTechnique()
        
        // Initialize arSession AFTER arSCNView is set up
        arSession = arSCNView.session
        arSession.delegate = self
    }
    
    // MARK: - Bloom/Glow Post-Processing
    
    private func applyBloomTechnique() {
        // SCNTechnique-based bloom for neon glow effect
        // This makes any emissive material appear to glow
        let techniqueDict: [String: Any] = [
            "passes": [
                "bloom": [
                    "draw": "DRAW_SCENE",
                    "inputs": [:],
                    "outputs": ["color": "COLOR"],
                    "colorStates": [
                        "clear": true,
                        "clearColor": "0.0 0.0 0.0 0.0"
                    ]
                ]
            ],
            "sequence": ["bloom"],
            "symbols": [:]
        ]
        
        if let technique = SCNTechnique(dictionary: techniqueDict) {
            arSCNView.technique = technique
        }
    }
    
    // MARK: - AR Session Configuration
    
    func startARSession() {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable LiDAR mesh if available (creates the digital twin wireframe)
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            configuration.sceneReconstruction = .meshWithClassification
        } else if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        // Fallback: still works without LiDAR — uses plane detection only
        
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Enable scene depth if available (LiDAR)
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stopARSession() {
        arSession.pause()
    }
    
    // MARK: - Object Tracking
    
    func addTrackedObject(at position: SIMD3<Float>) -> UUID {
        let objectId = UUID()
        let trackedObject = TrackedObject(id: objectId, initialPosition: position, lastPosition: position)
        trackedObjects[objectId] = trackedObject
        
        // Create glowing tracking sphere
        let sphere = SCNSphere(radius: 0.012)
        let material = SCNMaterial()
        material.diffuse.contents = neonCyan
        material.emission.contents = neonCyan  // Makes it glow with bloom
        material.emission.intensity = 1.5
        sphere.firstMaterial = material
        
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(position.x, position.y, position.z)
        node.name = "tracked_\(objectId.uuidString)"
        
        // Add a pulsing ring around the tracked point
        let ring = SCNTorus(ringRadius: 0.025, pipeRadius: 0.002)
        let ringMaterial = SCNMaterial()
        ringMaterial.diffuse.contents = neonCyan.withAlphaComponent(0.6)
        ringMaterial.emission.contents = neonCyan
        ringMaterial.emission.intensity = 1.0
        ring.firstMaterial = ringMaterial
        
        let ringNode = SCNNode(geometry: ring)
        ringNode.name = "tracking_ring"
        
        // Animate the ring pulsing
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.3, duration: 0.8),
            SCNAction.scale(to: 1.0, duration: 0.8)
        ])
        ringNode.runAction(SCNAction.repeatForever(pulseAction))
        
        node.addChildNode(ringNode)
        arSCNView.scene.rootNode.addChildNode(node)
        
        return objectId
    }
    
    func updateTrackedObject(_ objectId: UUID, to newPosition: SIMD3<Float>) {
        guard var trackedObject = trackedObjects[objectId] else { return }
        
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - trackedObject.lastUpdateTime
        
        guard deltaTime > 0.001 else { return } // Skip if too fast
        
        // Calculate kinematics using PhysicsEngine
        let velocity = physicsEngine.calculateVelocity(
            previousPosition: trackedObject.lastPosition,
            currentPosition: newPosition,
            deltaTime: deltaTime
        )
        let acceleration = physicsEngine.calculateAcceleration(
            previousVelocity: trackedObject.lastVelocity,
            currentVelocity: velocity,
            deltaTime: deltaTime
        )
        
        trackedObject.velocity = velocity
        trackedObject.acceleration = acceleration
        trackedObject.lastPosition = newPosition
        trackedObject.lastUpdateTime = currentTime
        trackedObject.lastVelocity = velocity
        trackedObjects[objectId] = trackedObject
        
        // Update visual position
        if let node = arSCNView.scene.rootNode.childNode(withName: "tracked_\(objectId.uuidString)", recursively: true) {
            node.position = SCNVector3(newPosition.x, newPosition.y, newPosition.z)
            
            if showVectors {
                updateVelocityArrow(for: trackedObject, parentNode: node)
                updateAccelerationArrow(for: trackedObject, parentNode: node)
            } else {
                node.childNode(withName: "vel_arrow", recursively: false)?.removeFromParentNode()
                node.childNode(withName: "accel_arrow", recursively: false)?.removeFromParentNode()
            }
        }
        
        // Trajectory ghosting
        if recordingPath {
            trajectoryPoints.append(newPosition)
            if trajectoryPoints.count > 200 {
                trajectoryPoints.removeFirst()
            }
            updateTrajectoryGhosting()
        }
        
        // Send data back to ViewModel for charting
        onTrackingUpdate?(newPosition, velocity, acceleration)
    }
    
    // MARK: - Vector Arrows with Arrowheads
    
    private func createArrow(direction: SIMD3<Float>, magnitude: Float, color: UIColor, name: String) -> SCNNode {
        let arrowNode = SCNNode()
        arrowNode.name = name
        
        let scaledLength = min(magnitude * 0.15, 0.3) // Cap max length
        guard scaledLength > 0.005 else { return arrowNode }
        
        // Shaft (cylinder)
        let shaft = SCNCylinder(radius: 0.0025, height: CGFloat(scaledLength))
        let shaftMaterial = SCNMaterial()
        shaftMaterial.diffuse.contents = color
        shaftMaterial.emission.contents = color
        shaftMaterial.emission.intensity = 1.2
        shaft.firstMaterial = shaftMaterial
        
        let shaftNode = SCNNode(geometry: shaft)
        shaftNode.position = SCNVector3(0, scaledLength / 2, 0) // Center along Y
        arrowNode.addChildNode(shaftNode)
        
        // Arrowhead (cone)
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.006, height: 0.015)
        let coneMaterial = SCNMaterial()
        coneMaterial.diffuse.contents = color
        coneMaterial.emission.contents = color
        coneMaterial.emission.intensity = 1.5
        cone.firstMaterial = coneMaterial
        
        let coneNode = SCNNode(geometry: cone)
        coneNode.position = SCNVector3(0, scaledLength, 0) // At the tip
        arrowNode.addChildNode(coneNode)
        
        // Orient arrow along the direction vector
        let dir = normalize(direction)
        let up = SIMD3<Float>(0, 1, 0)
        
        if abs(dot(dir, up)) < 0.999 {
            let right = normalize(cross(up, dir))
            let correctedUp = cross(dir, right)
            
            let rotationMatrix = simd_float4x4(columns: (
                SIMD4<Float>(right.x, right.y, right.z, 0),
                SIMD4<Float>(dir.x, dir.y, dir.z, 0),
                SIMD4<Float>(correctedUp.x, correctedUp.y, correctedUp.z, 0),
                SIMD4<Float>(0, 0, 0, 1)
            ))
            arrowNode.simdTransform = rotationMatrix
        }
        
        return arrowNode
    }
    
    private func updateVelocityArrow(for object: TrackedObject, parentNode: SCNNode) {
        parentNode.childNode(withName: "vel_arrow", recursively: false)?.removeFromParentNode()
        
        let speed = length(object.velocity)
        guard speed > 0.01 else { return }
        
        let arrow = createArrow(
            direction: object.velocity,
            magnitude: speed,
            color: velocityRed,
            name: "vel_arrow"
        )
        parentNode.addChildNode(arrow)
    }
    
    private func updateAccelerationArrow(for object: TrackedObject, parentNode: SCNNode) {
        parentNode.childNode(withName: "accel_arrow", recursively: false)?.removeFromParentNode()
        
        let accelMag = length(object.acceleration)
        guard accelMag > 0.05 else { return }
        
        let arrow = createArrow(
            direction: object.acceleration,
            magnitude: accelMag,
            color: accelBlue,
            name: "accel_arrow"
        )
        parentNode.addChildNode(arrow)
    }
    
    // MARK: - Trajectory Ghosting with Opacity Fade
    
    private func updateTrajectoryGhosting() {
        currentTrajectoryNode?.removeFromParentNode()
        
        guard trajectoryPoints.count >= 2 else { return }
        
        let containerNode = SCNNode()
        containerNode.name = "trajectory_ghost"
        
        // Draw line segments with fading opacity (older = more transparent)
        let totalPoints = trajectoryPoints.count
        for i in 0..<(totalPoints - 1) {
            let start = trajectoryPoints[i]
            let end = trajectoryPoints[i + 1]
            
            let opacity = Float(i) / Float(totalPoints) * 0.8 + 0.1 // Fade from 0.1 to 0.9
            
            let vertices = [
                SCNVector3(start.x, start.y, start.z),
                SCNVector3(end.x, end.y, end.z)
            ]
            let source = SCNGeometrySource(vertices: vertices)
            let element = SCNGeometryElement(indices: [UInt16(0), UInt16(1)], primitiveType: .line)
            let lineGeometry = SCNGeometry(sources: [source], elements: [element])
            
            let material = SCNMaterial()
            material.diffuse.contents = neonCyan.withAlphaComponent(CGFloat(opacity))
            material.emission.contents = neonCyan.withAlphaComponent(CGFloat(opacity * 0.8))
            material.emission.intensity = 1.0
            lineGeometry.firstMaterial = material
            
            let lineNode = SCNNode(geometry: lineGeometry)
            containerNode.addChildNode(lineNode)
        }
        
        // Add small spheres at intervals for "ghost" effect
        let step = max(1, totalPoints / 15)
        for i in stride(from: 0, to: totalPoints, by: step) {
            let point = trajectoryPoints[i]
            let opacity = Float(i) / Float(totalPoints) * 0.6 + 0.1
            
            let ghostSphere = SCNSphere(radius: 0.004)
            let mat = SCNMaterial()
            mat.diffuse.contents = neonCyan.withAlphaComponent(CGFloat(opacity))
            mat.emission.contents = neonCyan.withAlphaComponent(CGFloat(opacity))
            mat.emission.intensity = 0.8
            ghostSphere.firstMaterial = mat
            
            let ghostNode = SCNNode(geometry: ghostSphere)
            ghostNode.position = SCNVector3(point.x, point.y, point.z)
            containerNode.addChildNode(ghostNode)
        }
        
        arSCNView.scene.rootNode.addChildNode(containerNode)
        currentTrajectoryNode = containerNode
    }
    
    // MARK: - ARSCNViewDelegate — Plane Detection
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            addPlaneGrid(to: node, for: planeAnchor)
        }
        
        // LiDAR mesh wireframe overlay
        if let meshAnchor = anchor as? ARMeshAnchor {
            addMeshWireframe(to: node, for: meshAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            updatePlaneGrid(node: node, for: planeAnchor)
        }
        
        if let meshAnchor = anchor as? ARMeshAnchor {
            updateMeshWireframe(node: node, for: meshAnchor)
        }
    }
    
    // MARK: - Blueprint Grid on Detected Planes
    
    private func addPlaneGrid(to node: SCNNode, for anchor: ARPlaneAnchor) {
        let width = CGFloat(anchor.planeExtent.width)
        let height = CGFloat(anchor.planeExtent.height)
        
        let plane = SCNPlane(width: width, height: height)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = neonCyan.withAlphaComponent(0.05)
        planeMaterial.emission.contents = neonCyan.withAlphaComponent(0.03)
        planeMaterial.isDoubleSided = true
        plane.firstMaterial = planeMaterial
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
        planeNode.name = "plane_surface"
        
        // Add grid lines on the plane
        let gridNode = createGridOnPlane(width: Float(width), depth: Float(height), spacing: 0.1)
        gridNode.eulerAngles.x = -.pi / 2
        gridNode.position = SCNVector3(anchor.center.x, 0.001, anchor.center.z)
        gridNode.name = "plane_grid"
        
        node.addChildNode(planeNode)
        node.addChildNode(gridNode)
    }
    
    private func updatePlaneGrid(node: SCNNode, for anchor: ARPlaneAnchor) {
        // Remove old grid and surface
        node.childNode(withName: "plane_surface", recursively: false)?.removeFromParentNode()
        node.childNode(withName: "plane_grid", recursively: false)?.removeFromParentNode()
        
        // Re-add with updated dimensions
        addPlaneGrid(to: node, for: anchor)
    }
    
    private func createGridOnPlane(width: Float, depth: Float, spacing: Float) -> SCNNode {
        let gridNode = SCNNode()
        
        let halfW = width / 2
        let halfD = depth / 2
        
        var vertices: [SCNVector3] = []
        var indices: [UInt32] = []
        var idx: UInt32 = 0
        
        // Lines along X
        for z in stride(from: -halfD, through: halfD, by: spacing) {
            vertices.append(SCNVector3(-halfW, 0, z))
            vertices.append(SCNVector3(halfW, 0, z))
            indices.append(idx); indices.append(idx + 1)
            idx += 2
        }
        
        // Lines along Z
        for x in stride(from: -halfW, through: halfW, by: spacing) {
            vertices.append(SCNVector3(x, 0, -halfD))
            vertices.append(SCNVector3(x, 0, halfD))
            indices.append(idx); indices.append(idx + 1)
            idx += 2
        }
        
        guard !vertices.isEmpty else { return gridNode }
        
        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: indices.map(UInt16.init), primitiveType: .line)
        let gridGeometry = SCNGeometry(sources: [source], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = neonCyanDim
        material.emission.contents = neonCyan.withAlphaComponent(0.15)
        material.emission.intensity = 0.5
        gridGeometry.firstMaterial = material
        
        gridNode.geometry = gridGeometry
        return gridNode
    }
    
    // MARK: - LiDAR Mesh Wireframe (Digital Twin)
    
    private func addMeshWireframe(to node: SCNNode, for meshAnchor: ARMeshAnchor) {
        let meshGeometry = meshAnchor.geometry
        
        // Extract vertices using direct buffer access
        let vertexSource = meshGeometry.vertices
        let vertexCount = vertexSource.count
        var vertices: [SCNVector3] = []
        
        let vertexPointer = vertexSource.buffer.contents().advanced(by: vertexSource.offset)
        for i in 0..<vertexCount {
            let floats = vertexPointer.advanced(by: vertexSource.stride * i).assumingMemoryBound(to: Float.self)
            vertices.append(SCNVector3(floats[0], floats[1], floats[2]))
        }
        
        // Extract face indices for wireframe
        let faceSource = meshGeometry.faces
        let faceCount = faceSource.count
        var lineIndices: [UInt32] = []
        let bytesPerIndex = faceSource.bytesPerIndex
        
        let bufferPointer = faceSource.buffer.contents()
        for i in 0..<faceCount {
            let faceStartOffset = bytesPerIndex * 3 * i
            let faceOffset = bufferPointer.advanced(by: faceStartOffset)
            let idx0: UInt32
            let idx1: UInt32
            let idx2: UInt32
            
            if bytesPerIndex == 4 {
                let uint32s = faceOffset.assumingMemoryBound(to: UInt32.self)
                idx0 = uint32s[0]; idx1 = uint32s[1]; idx2 = uint32s[2]
            } else {
                let uint16s = faceOffset.assumingMemoryBound(to: UInt16.self)
                idx0 = UInt32(uint16s[0]); idx1 = UInt32(uint16s[1]); idx2 = UInt32(uint16s[2])
            }
            
            // Draw 3 edges per triangle
            lineIndices.append(contentsOf: [idx0, idx1, idx1, idx2, idx2, idx0])
        }
        
        guard !vertices.isEmpty, !lineIndices.isEmpty else { return }
        
        let source = SCNGeometrySource(vertices: vertices)
        let element = SCNGeometryElement(indices: lineIndices.map(UInt16.init), primitiveType: .line)
        let wireGeometry = SCNGeometry(sources: [source], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = neonCyan.withAlphaComponent(0.1)
        material.emission.contents = neonCyan.withAlphaComponent(0.08)
        material.emission.intensity = 0.5
        material.isDoubleSided = true
        wireGeometry.firstMaterial = material
        
        let wireNode = SCNNode(geometry: wireGeometry)
        wireNode.name = "mesh_wire"
        node.addChildNode(wireNode)
        
        meshOverlayNodes[meshAnchor.identifier] = wireNode
    }
    
    private func updateMeshWireframe(node: SCNNode, for meshAnchor: ARMeshAnchor) {
        node.childNode(withName: "mesh_wire", recursively: false)?.removeFromParentNode()
        addMeshWireframe(to: node, for: meshAnchor)
    }
    
    // MARK: - Public API
    
    func clearTrajectory() {
        trajectoryPoints.removeAll()
        currentTrajectoryNode?.removeFromParentNode()
        currentTrajectoryNode = nil
    }
}

// MARK: - ARSessionDelegate

extension KineprintARView {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Handle frame updates if needed
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Handle session failures
        print("AR Session failed with error: \(error)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Handle session interruption
        print("AR Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Handle session resumption
        print("AR Session interruption ended")
    }
}

// MARK: - Tracked Object Data

struct TrackedObject {
    let id: UUID
    var initialPosition: SIMD3<Float>
    var lastPosition: SIMD3<Float>
    var velocity: SIMD3<Float> = .zero
    var acceleration: SIMD3<Float> = .zero
    var lastVelocity: SIMD3<Float> = .zero
    var lastUpdateTime: CFTimeInterval = CACurrentMediaTime()
}
#endif

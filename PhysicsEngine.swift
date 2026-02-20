import Foundation
import Combine
#if os(iOS)
import ARKit
import SceneKit
#endif
import simd

@available(macOS 10.15, *)
@available(iOS 16.0, *)
@MainActor
class PhysicsEngine: ObservableObject {
    static let shared = PhysicsEngine()
    
    private init() {}
    
    // All calculations happen locally on device - 100% offline
    // Calculate real-world distances using LiDAR data
    func calculateRealWorldDistance(from cameraTransform: matrix_float4x4, to point: simd_float3) -> Float {
        // Extract camera position from transform matrix
        let cameraPosition = simd_float3(cameraTransform.columns.3.x, 
                                         cameraTransform.columns.3.y, 
                                         cameraTransform.columns.3.z)
        
        // Calculate Euclidean distance - all computation local
        let dx = point.x - cameraPosition.x
        let dy = point.y - cameraPosition.y
        let dz = point.z - cameraPosition.z
        
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    // Calculate velocity in m/s given positions and timestamps - all offline
    func calculateVelocity(previousPosition: simd_float3, 
                          currentPosition: simd_float3, 
                          deltaTime: TimeInterval) -> simd_float3 {
        if deltaTime <= 0 {
            return simd_float3(0, 0, 0)
        }
        
        let displacement = simd_float3(
            currentPosition.x - previousPosition.x,
            currentPosition.y - previousPosition.y,
            currentPosition.z - previousPosition.z
        )
        
        return displacement / Float(deltaTime)
    }
    
    // Calculate acceleration given velocities and timestamps
    func calculateAcceleration(previousVelocity: simd_float3, 
                             currentVelocity: simd_float3, 
                             deltaTime: TimeInterval) -> simd_float3 {
        if deltaTime <= 0 {
            return simd_float3(0, 0, 0)
        }
        
        let velocityChange = simd_float3(
            currentVelocity.x - previousVelocity.x,
            currentVelocity.y - previousVelocity.y,
            currentVelocity.z - previousVelocity.z
        )
        
        return velocityChange / Float(deltaTime)
    }
    
    // Normalize a vector to unit length
    func normalizeVector(_ vector: simd_float3) -> simd_float3 {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        if length == 0 {
            return simd_float3(0, 0, 0)
        }
        return simd_float3(
            vector.x / length,
            vector.y / length,
            vector.z / length
        )
    }
    
    // Calculate the magnitude of a vector
    func magnitude(of vector: simd_float3) -> Float {
        return sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }
    
    // Calculate trajectory points for ghosting effect
    func calculateTrajectoryPoints(initialPosition: simd_float3, 
                                  initialVelocity: simd_float3, 
                                  gravity: Float = 9.81, 
                                  timeStep: Float = 0.1, 
                                  numSteps: Int = 20) -> [simd_float3] {
        var points: [simd_float3] = []
        var position = initialPosition
        var velocity = initialVelocity
        
        for _ in 0..<numSteps {
            // Update position based on velocity
            position = simd_float3(
                position.x + velocity.x * timeStep,
                position.y + velocity.y * timeStep,
                position.z + velocity.z * timeStep
            )
            
            // Apply gravity to vertical component
            velocity = simd_float3(
                velocity.x,  // Horizontal velocity remains constant (neglecting air resistance)
                velocity.y - gravity * timeStep,  // Gravity affects vertical velocity
                velocity.z
            )
            
            points.append(position)
        }
        
        return points
    }
    
    // Calculate vector projection onto a plane
    func projectVectorOntoPlane(vector: simd_float3, planeNormal: simd_float3) -> simd_float3 {
        let dotProduct = vector.x * planeNormal.x + vector.y * planeNormal.y + vector.z * planeNormal.z
        let normalMagnitudeSquared = planeNormal.x * planeNormal.x + planeNormal.y * planeNormal.y + planeNormal.z * planeNormal.z
        
        if normalMagnitudeSquared == 0 {
            return vector  // Cannot project onto zero vector
        }
        
        let projectionFactor = dotProduct / normalMagnitudeSquared
        
        return simd_float3(
            vector.x - projectionFactor * planeNormal.x,
            vector.y - projectionFactor * planeNormal.y,
            vector.z - projectionFactor * planeNormal.z
        )
    }
    
    // Calculate angle between two vectors in radians
    func angleBetweenVectors(_ v1: simd_float3, _ v2: simd_float3) -> Float {
        let dotProduct = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
        let magnitudes = magnitude(of: v1) * magnitude(of: v2)
        
        if magnitudes == 0 {
            return 0  // Cannot calculate angle with zero vector
        }
        
        let cosAngle = max(-1.0, min(1.0, dotProduct / magnitudes))
        return acos(cosAngle)
    }
    
    // Calculate velocity in meters per second with LiDAR precision
    func calculateMetersPerSecondVelocity(from previousPose: matrix_float4x4, 
                                        to currentPose: matrix_float4x4, 
                                        deltaTime: TimeInterval) -> simd_float3 {
        // Extract positions from transformation matrices
        let prevPos = simd_float3(
            previousPose.columns.3.x,
            previousPose.columns.3.y,
            previousPose.columns.3.z
        )
        
        let currPos = simd_float3(
            currentPose.columns.3.x,
            currentPose.columns.3.y,
            currentPose.columns.3.z
        )
        
        return calculateVelocity(previousPosition: prevPos, 
                               currentPosition: currPos, 
                               deltaTime: deltaTime)
    }
}
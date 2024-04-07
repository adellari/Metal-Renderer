//
//  Extensions.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 4/2/24.
//

import SwiftUI
import simd

struct CameraParams{
    var WorldToCamera : float4x4;
    var ProjectionInv: float4x4;
    var dummy: Float;
}

extension UIImageView {
    func asSwiftUIView() -> some View {
        return ImageViewWrapper(uiImageView: self)
    }
}

struct ImageViewWrapper: UIViewRepresentable {
    let uiImageView: UIImageView

    func makeUIView(context: Context) -> UIImageView {
        return uiImageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Update the view if needed
    }
}

extension float4x4{
    func CameraToWorld(origin: float3, target: float3, up: float3, fov: Float, aspect: Float, near: Float, far: Float) -> float4x4{
        
        let zAxis = float3(normalize(origin - target))
        let xAxis = normalize(cross(up, zAxis))
        let yAxis = normalize(cross(zAxis, xAxis))
        
        let xDotOrigin = -dot(xAxis, origin)
        let yDotOrigin = -dot(yAxis, origin)
        let zDotOrigin = -dot(zAxis, origin)
        
        let tanHalfFov = tan(fov/2.0 * Float.pi/180)
        
        let P = float4x4([
            float4(1.0 / (aspect * tanHalfFov), 0, 0, 0),
            float4(0, 1.0 / tanHalfFov, 0, 0),
            float4(0, 0, -(far + near) / (far - near), -1),
            float4(0, 0, -(2 * far * near) / (far - near), 0)
        ])
        
        //view matrix * projection matrix
        let CameraToWorld = P * float4x4([float4(xAxis.x, yAxis.x, zAxis.x, 0),
                                          float4(xAxis.y, yAxis.y, zAxis.y, 0),
                                          float4(xAxis.z, yAxis.z, zAxis.z, 0),
                                          float4(xDotOrigin, yDotOrigin, zDotOrigin, 1)
                                         ])
        return CameraToWorld
    }
    
    func Projection(fov: Float, aspect: Float, near: Float, far: Float) -> float4x4{
        let tanHalfFov = tan(fov/2.0 * Float.pi/180)
        
        let P = float4x4([
            float4(1.0 / (aspect * tanHalfFov), 0, 0, 0),
            float4(0, 1.0 / tanHalfFov, 0, 0),
            float4(0, 0, -(far + near) / (far - near), -1),
            float4(0, 0, -(2 * far * near) / (far - near), 0)
        ])
        
        return P
    }
}

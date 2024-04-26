//
//  Extensions.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 4/2/24.
//

import SwiftUI
import simd
import GLKit

struct CameraParams{
    var WorldToCamera : float4x4;
    var ProjectionInv: float4x4;
    var cameraPosition: float3;
    var dummy: Float;
}

struct Sphere {
    var point : float4; //position, size
    var albedo : float3;
    var specular : float3;
    var emission : float3;
    var refractiveColor : float3;
    var smoothness : Float;
    var IOR : Float;
    var internalSmoothness : Float;
    var transmissionChance : Float;
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
    func WorldToCamera(eye: float3, target: float3, up: float3, fov: Float, aspect: Float, near: Float, far: Float, translation: Float) -> float4x4{
        
        let zAxis = float3(normalize(eye - target)) //foward
        let xAxis = normalize(cross(up, zAxis))     //right
        let yAxis = normalize(cross(zAxis, xAxis))  //up
        
        //the rotation matrix
        //for our case this is an identity matrix
        //since our world is the usual x - right, y - up, z - forward
        
        let R = float4x4([float4(xAxis.x, yAxis.x, zAxis.x, 0),
                          float4(xAxis.y, yAxis.y, zAxis.y, 0),
                          float4(xAxis.z, yAxis.z, zAxis.z, 0),
                          float4(0, 0, 0, 1)
                         ])
        
        /*
        let R = float4x4([float4(1, 0, 0, 0),
                          float4(0, 1, 0, 0),
                          float4(0, 0, 1, 0),
                          float4(0, 0, 0, 1)
                         ])
         */
        
        //the translation matrix
        let T = float4x4([float4(1, 0, 0, 0),
                          float4(0, 1, 0, 0),
                          float4(0, 0, 1, 0),
                          float4(-eye.x, -eye.y, -eye.z, 1)])
        
        //view matrix * projection matrix
        let WorldToCamera = (T * R).inverse
        return WorldToCamera
    }
    
    func Projection(fov: Float, aspect: Float, near: Float, far: Float) -> float4x4{
        let tanHalfFov = tan((fov/2.0) * Float.pi/180)
        
        let P = float4x4([
            float4(1.0 / (aspect * tanHalfFov), 0, 0, 0),
            float4(0, -1.0 / tanHalfFov, 0, 0),
            float4(0, 0, -(far + near) / (far - near), -1),
            float4(0, 0, -(2 * far * near) / (far - near), 0)
        ])
        
        return P
    }
    
    func CreateProjection(fov: Float, aspect: Float, near: Float, far: Float) -> float4x4{
        let y = 1.0 / tan(GLKMathDegreesToRadians(fov) / 2.0)
        let x = y / aspect
        
        let zRange = far - near
        let zNear = near
        
        var m00 = -x
        var m11 = -y
        var m22 = (far + near) / zRange
        var m23 = -1
        var m32 = 2 * zNear * far / zRange
        
        //a 90 degree clockwise rotation
        // i can vision this by creating the vector space with my LEFT hand -> L
        // rotate the space along its z axis by 90 degrees
        // you see what was x axis becomes the y (0, 1, 0)
        // and y is now -x (-1, 0, 0)
        //populate the matrix with these values : )
        let rotationMatrix = simd_float4x4(
                simd_float4(0, -1, 0, 0),
                simd_float4(1, 0, 0, 0),
                simd_float4(0, 0, 1, 0),
                simd_float4(0, 0, 0, 1)
            )
        
        
        return float4x4([float4(m00, 0, 0, 0),
                        float4(0, m11, 0, 0),
                        float4(0, 0, m22, -1),
                        float4(0, 0, m32, 0)]) // * rotationMatrix
        
        
    }
}

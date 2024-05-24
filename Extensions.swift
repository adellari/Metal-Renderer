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
    var focalLength: Float;
    var aperture: Float;
    var dummy: Float;
}

/*
 s.specular = 0.1f;
 s.emission = 0.f;
 s.smoothness = 3.f;
 s.refractionColor = 1.f;
 s.refractiveIndex = 1.8f;
 s.refractionChance = 1.f;
 s.point = float4(0, 0.4f, 0.f, 0.3f);
 s.albedo = float3(0.1f, 0.42f, 0.93f);
 */

struct Sphere {
    var point : float4 = float4(0, 2, 0, 1.3); //position, size
    var albedo : float3 = float3(0.1, 0.42, 0.93);
    var specular : float3 = float3(0.1, 0.1, 0.1);
    var emission : float3 = float3(0, 0, 0);
    var refractiveColor : float3 = float3(0.3, 0.3, 0.3);
    var smoothness : Float = 3;
    var IOR : Float = 1.8;
    var internalSmoothness : Float = 1;
    var transmissionChance : Float = 1;
}

struct Triangle {
    var v0 : float3 = float3(-4.5, 7, -3);
    var v1 : float3 = float3(3, 0, -3);
    var v2 : float3 = float3(3, 7, -3);
    var centroid : float3 = float3();
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

//
//  DataModels.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 5/19/24.
//

import Foundation
import SwiftUI
import simd

class SceneDataModel: ObservableObject {
    @Published var cameraView: Double = 0.0
    @Published var sampleCount : Int = 0
    @Published var cameraOffset: (Float, Float, Float) = (0.0, 0.0, 1.0)
    @Published var focalLength: Double = 70
    @Published var aperture: Double = 0.1
    @Published var skybox: String = "desert-sky"
    @Published var Denoiser: OIDNHandler = OIDNHandler()
    @Published var Spheres : [Sphere] = [Sphere(), Sphere()] {
        didSet{
            //print("hi, there was a change to the spheres")
            sampleCount = -2
            //print(Spheres)
        }
    }
    @Published var Triangles : [Triangle] = [Triangle(), Triangle(v0: float3(-4.5, 0, -3), v1: float3(3, 0, -3), v2: float3(-4.5, 5, -3))]
    @Published var Meshloader : MeshLoader? = MeshLoader()
    @Published var BVH : BVHBuilder?
}

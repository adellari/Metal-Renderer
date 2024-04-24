//
//  Encoder.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import Metal
import simd


//Prepares the pipeline and uinforms
final class PipelineEncoder{
    var tint: Float = .zero
    private var deviceSupportsNonuniformThreadgroups: Bool
    private let pipelineState: MTLComputePipelineState
    public var sceneParams: SceneDataModel = SceneDataModel()
    
    
    init(library: MTLLibrary) throws{
        self.deviceSupportsNonuniformThreadgroups = library.device.supportsFeatureSet(.iOS_GPUFamily4_v1)
        let constantValues = MTLFunctionConstantValues()
        constantValues.setConstantValue(&self.deviceSupportsNonuniformThreadgroups, type: .bool, index: 0)
        let function = try library.makeFunction(name: "Tracer", constantValues: constantValues)
        self.pipelineState = try library.device.makeComputePipelineState(function: function)
    }
    
    //encode uniforms,, pipeline state, and execution parameters into the commandbuffer
    func encode(source: MTLTexture, destination: MTLTexture, in commandBuffer: MTLCommandBuffer){
        guard let encoder = commandBuffer.makeComputeCommandEncoder()
        else{ return}
        
        let viewX = (Float.pi/180.0) * Float(self.sceneParams.cameraOffset.0)
        let viewY = (Float.pi/180.0) * self.sceneParams.cameraOffset.1;
        let translation = self.sceneParams.cameraOffset.2;
        
        //sin(5) * radius, 0, cos(5) * radius
        
        let eye = float3(0, 0, 0)
        let target = float3(sin(Float.pi - viewX), 0, 1 * cos(Float.pi - viewX ));
        //let target = float3(sin(viewX) * 5, 0, cos(viewX) * 5)
        let up = float3(0, 1, 0)
        
        
        
        //to take our 3d objects and bring them to camera space
        let WorldToCamera = float4x4().WorldToCamera(eye: eye, target: target, up: up, fov: 60.0, aspect: 2.0, near: 0.01, far: 100.0, translation: translation)
        //to take our screen (clip) coordinates and move them to world space
        let ProjectionInvMatrix = (float4x4().CreateProjection(fov: 60, aspect: 2.0, near: 0.01, far: 100.0))
        var viewAsFloat = Float(self.sceneParams.cameraView)
        var sampleCount = self.sceneParams.sampleCount
        var sampleJitter = float2(Float.random(in: 0..<1), Float.random(in: 0..<1))
        var camStruct = CameraParams(WorldToCamera: WorldToCamera, ProjectionInv: ProjectionInvMatrix, cameraPosition: float3(1.0 * sin(viewX * 0), 0.4, 1.0 * cos(viewX * 0)), dummy: Float.random(in: 0..<1))
        var camBuffer = encoder.device.makeBuffer(bytes: &camStruct, length: MemoryLayout<CameraParams>.stride, options: [])
        
        
        
        encoder.label = "Pathtracer"
        encoder.setTexture(source, index: 0)
        encoder.setTexture(destination, index: 1)
        encoder.setBytes(&viewAsFloat, length: MemoryLayout<Float>.stride, index: 0)
        encoder.setBytes(&sampleCount, length: MemoryLayout<Int>.stride, index: 3)
        encoder.setBytes(&sampleJitter, length: MemoryLayout<float2>.stride, index: 4)
        encoder.setBuffer(camBuffer, offset: 0, index: 1)
        //encoder.setBytes(&WorldToCamera, length: MemoryLayout<float4x4>.size, index: 1)
        //encoder.setBytes(&ProjectionInvMatrix, length: MemoryLayout<float4x4>.size, index: 2)
        
       
        let threadGroupSize = MTLSize(width: 32, height: 32, depth: 1)
        let threadCountPerGroup = MTLSize(width: destination.width / 32, height: destination.height / 32, depth: 1)
        
        encoder.setComputePipelineState(self.pipelineState)
        //encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        encoder.dispatchThreadgroups(threadGroupSize, threadsPerThreadgroup: threadCountPerGroup)
        
        
        encoder.endEncoding()
    }
}
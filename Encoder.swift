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
        
        let eye = float3(0, 0, 5)
        let target = float3(0, 0, 0)
        let up = float3(0, 1, 0)
        
        //take an inverse of the camera to world
        var WorldToCamera = float4x4().CameraToWorld(origin: eye, target: target, up: up, fov: 60.0, aspect: 2.0, near: 0.1, far: 100.0).inverse
        var ProjectionInvMatrix = float4x4().Projection(fov: 60.0, aspect: 2.0, near: 0.1, far: 100.0).inverse

        
        encoder.label = "Pathtracer"
        encoder.setTexture(source, index: 0)
        encoder.setTexture(destination, index: 1)
        /*
        encoder.setBytes(&self.tint, length: MemoryLayout<Float>.stride, index: 0)
        encoder.setBytes(&WorldToCamera, length: MemoryLayout<float4x4>.size, index: 1)
        encoder.setBytes(&ProjectionInvMatrix, length: MemoryLayout<float4x4>.size, index: 2)*/
        
        let threadDimensions = MTLSize(width: source.width, height: source.height, depth: 1)
        let threadGroupsX = self.pipelineState.threadExecutionWidth
        let threadGroupsY = self.pipelineState.maxTotalThreadsPerThreadgroup / threadGroupsX
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadCountPerGroup = MTLSize(width: source.width / 16, height: source.height / 16, depth: 1)
        
        encoder.setComputePipelineState(self.pipelineState)
        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatchThreadgroups(threadDimensions, threadsPerThreadgroup: threadGroupSize)
        }
        else {
            let threadGroupCount = MTLSize(width: (threadDimensions.width + threadGroupSize.width - 1) / threadGroupSize.width, height: (threadDimensions.height + threadGroupSize.height - 1) / threadGroupSize.height, depth: 1)
            
            //encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
            encoder.dispatchThreadgroups(threadGroupSize, threadsPerThreadgroup: threadCountPerGroup)
        }
        
        encoder.endEncoding()
    }
}

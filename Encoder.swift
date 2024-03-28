//
//  Encoder.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import Metal


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
    
    func encode(source: MTLTexture, destination: MTLTexture, in commandBuffer: MTLCommandBuffer){
        guard let encoder = commandBuffer.makeComputeCommandEncoder()
        else{ return}
        
        encoder.label = "Pathtracer"
        encoder.setTexture(source, index: 0)
        encoder.setTexture(destination, index: 1)
        encoder.setBytes(&self.tint, length: MemoryLayout<Float>.stride, index: 0)
        
        let threadDimensions = MTLSize(width: source.width, height: source.height, depth: 1)
        let threadGroupsX = self.pipelineState.threadExecutionWidth
        let threadGroupsY = self.pipelineState.maxTotalThreadsPerThreadgroup / threadGroupsX
        let threadGroupSize = MTLSize(width: threadGroupsX, height: threadGroupsY, depth: 1)
        
        encoder.setComputePipelineState(self.pipelineState)
        if self.deviceSupportsNonuniformThreadgroups {
            encoder.dispatchThreadgroups(threadDimensions, threadsPerThreadgroup: threadGroupSize)
        }
        else {
            let threadGroupCount = MTLSize(width: (threadDimensions.width + threadGroupSize.width - 1) / threadGroupSize.width, height: (threadDimensions.height + threadGroupSize.height - 1) / threadGroupSize.height, depth: 1)
            
            encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        }
        
        encoder.endEncoding()
    }
}

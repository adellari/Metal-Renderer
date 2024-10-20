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
    private let Tracer: MTLComputePipelineState
    private let DebugTracer: MTLComputePipelineState
    public var sceneParams: SceneDataModel// = SceneDataModel()
    public var cameraBuffer: MTLBuffer?
    public var spheresBuffer: MTLBuffer?
    public var trisBuffer: MTLBuffer?
    public var trisOptsBuffer: MTLBuffer?
    public var trisIndicesBuffer: MTLBuffer?
    public var bvhBuffer: MTLBuffer?
    
    init(library: MTLLibrary, scene: SceneDataModel) throws{
        self.deviceSupportsNonuniformThreadgroups = library.device.supportsFeatureSet(.iOS_GPUFamily4_v1)
        let constantValues = MTLFunctionConstantValues()
        constantValues.setConstantValue(&self.deviceSupportsNonuniformThreadgroups, type: .bool, index: 0)
        let Tracefunction = try library.makeFunction(name: "Tracer", constantValues: constantValues)
        let DebugFunction = try library.makeFunction(name: "DebugTracer", constantValues: constantValues)
        self.Tracer = try library.device.makeComputePipelineState(function: Tracefunction)
        self.DebugTracer = try library.device.makeComputePipelineState(function: DebugFunction)
        self.sceneParams = scene
    }
    
    func setReusables(encoder: MTLCommandEncoder)
    {
        //cameraBuffer = encoder.device.makeBuffer
    }
    
    //encode uniforms,, pipeline state, and execution parameters into the commandbuffer
    func encode(source: MTLTexture, destination: MTLTexture, albedo: MTLTexture, normal: MTLTexture, in commandBuffer: MTLCommandBuffer){
        guard let encoder = commandBuffer.makeComputeCommandEncoder()
        else{ return}
        
        let viewX = (Float.pi/180.0) * Float(self.sceneParams.cameraOffset.0)
        let viewY = (Float.pi/180.0) * self.sceneParams.cameraOffset.1;
        let translation = self.sceneParams.cameraOffset.2;
        
        //sin(5) * radius, 0, cos(5) * radius
        let theta = -(Float.pi - viewX);
        //let phi = (Float(self.sceneParams.focalLength) / 50) * Float.pi;
        let phi = (Float.pi - viewY) * 2;
        
        let _x = sin(theta) * cos(phi);
        let _y = sin(theta) * sin(phi);
        let _z = cos(theta);
        
        let eye = SIMD3<Float>(0, 0, 0)
        let target = normalize(SIMD3<Float>(_x, _y, _z));
        
        let right = cross(target, SIMD3<Float>(0, 1, 0));
        var up = normalize(cross(right, target));
        let WorldToCamera = float4x4().WorldToCamera(eye: SIMD3<Float>(0, 0, 0), phi: theta, theta: phi)
        let sp = self.sceneParams
        
        //to take our screen (clip) coordinates and move them to world space
        let ProjectionInvMatrix = (float4x4().CreateProjection(fov: 60, aspect: 2.0, near: 0.01, far: 100.0))
        var viewAsFloat = Float(sp.cameraView)
        var sampleCount = sp.sampleCount
        var sampleJitter = SIMD2<Float>(Float.random(in: 0..<1), Float.random(in: 0..<1))
        var camStruct = CameraParams(WorldToCamera: WorldToCamera, ProjectionInv: ProjectionInvMatrix, cameraPosition: SIMD3<Float>(5.0 * sin(viewX * 0) * translation, 0.4, 5.0 * cos(viewX * 0) * translation), focalLength: Float(sceneParams.focalLength), aperture: Float(sceneParams.aperture), dummy: Float.random(in: 0..<1))
        
        if cameraBuffer == nil
        {
            cameraBuffer  = encoder.device.makeBuffer(bytes: &camStruct, length: MemoryLayout<CameraParams>.stride, options: [])
            spheresBuffer = encoder.device.makeBuffer(bytes: &sp.Spheres, length: MemoryLayout<Sphere>.stride * sp.Spheres.count, options: [])
            trisBuffer = encoder.device.makeBuffer(bytes: &sp.BVH!.tris, length: MemoryLayout<Triangle>.stride * sp.BVH!.tris.count, options: [])
            trisIndicesBuffer = encoder.device.makeBuffer(bytes: &sp.BVH!.trisIndices, length: MemoryLayout<Int>.stride * sp.BVH!.trisIndices.count, options: [])
            trisOptsBuffer = encoder.device.makeBuffer(bytes: &sp.Meshloader!.triangleOptionals!, length: MemoryLayout<TriangleOpt>.stride * sp.Meshloader!.triangleOptionals!.count, options: [])
            bvhBuffer = encoder.device.makeBuffer(bytes: &sp.BVH!.BVHTree, length: MemoryLayout<BVHNode>.stride * sp.BVH!.BVHTree.count, options: [])
        }
        else 
        {
            let cameraPointer = cameraBuffer!.contents()
            let spheresPointer = spheresBuffer!.contents()
            let trisPointer = trisBuffer!.contents()
            let bvhPointer = bvhBuffer!.contents()
            let trisOptsPointer = trisOptsBuffer!.contents()
            let trisIndicesPointer = trisIndicesBuffer!.contents()
            
            memcpy(cameraPointer, &camStruct, MemoryLayout<CameraParams>.stride)
            memcpy(spheresPointer, &sp.Spheres, MemoryLayout<Sphere>.stride * sp.Spheres.count)
            memcpy(trisPointer, &sp.BVH!.tris, MemoryLayout<Triangle>.stride * sp.BVH!.tris.count)
            memcpy(trisOptsPointer, &sp.Meshloader!.triangleOptionals!, MemoryLayout<TriangleOpt>.stride * sp.Meshloader!.triangleOptionals!.count)
            memcpy(trisIndicesPointer, &sp.BVH!.trisIndices, MemoryLayout<Int>.stride * sp.BVH!.trisIndices.count)
            memcpy(bvhPointer, &sp.BVH!.BVHTree, MemoryLayout<BVHNode>.stride * sp.BVH!.BVHTree.count)
        }
    
        
        encoder.label = "Pathtracer"
        encoder.setTexture(source, index: 0)
        encoder.setTexture(destination, index: 1)
        encoder.setTexture(albedo, index: 2)
        encoder.setTexture(normal, index: 3)
        
        //encoder.setBytes(&viewAsFloat, length: MemoryLayout<Float>.stride, index: 0)
        encoder.setBuffer(cameraBuffer, offset: 0, index: 0)
        encoder.setBuffer(spheresBuffer, offset: 0, index: 1)
        encoder.setBuffer(bvhBuffer, offset: 0, index: 2)
        encoder.setBuffer(trisOptsBuffer, offset: 0, index: 5)
        encoder.setBuffer(trisIndicesBuffer, offset: 0, index: 6)
        encoder.setBuffer(trisBuffer, offset: 0, index: 7)
        
        encoder.setBytes(&sampleCount, length: MemoryLayout<Int>.stride, index: 3)
        encoder.setBytes(&sampleJitter, length: MemoryLayout<SIMD2<Float>>.stride, index: 4)

       
        let threadGroupSize = MTLSize(width: 32, height: 32, depth: 1)
        let threadCountPerGroup = MTLSize(width: destination.width / 32, height: destination.height / 32, depth: 1)
        
        encoder.setComputePipelineState(self.Tracer)
        encoder.dispatchThreadgroups(threadGroupSize, threadsPerThreadgroup: threadCountPerGroup)
        
        
        encoder.endEncoding()
    }
}

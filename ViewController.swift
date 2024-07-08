//
//  ViewController.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import Foundation
import UIKit
import Metal
import Combine
import Swift

class ViewController {
    
    public var SceneData: SceneDataModel
    public var reloadTextures: Bool = false
    private let device: MTLDevice
    private let encoder: PipelineEncoder
    public let imageView: UIImageView
    public var denoisedView : UIImageView?
    private let commandQueue: MTLCommandQueue
    private let textureManager: TextureManager
    private var texturePair: (source: MTLTexture, destination: MTLTexture)?
    private var denoiserAuxilaries: (albedo: MTLTexture, normal: MTLTexture)?
    var cancellables: Set<AnyCancellable> = []
    
    
    init(device: MTLDevice, sceneData: SceneDataModel) throws{
        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let commandQueue = device.makeCommandQueue()          //make a command queue from the device
        else { throw Error.commandQueuereationFailed}
        self.device = device
        self.encoder = try .init(library: library, scene: sceneData)
        self.commandQueue = commandQueue
        self.textureManager = .init(device: device)
        self.SceneData = sceneData
        self.imageView = .init()
        //self.denoisedView = .init()
        //super.init(nibName: nil, bundle: nil)
        
        sceneData.objectWillChange.sink {   [weak self] _ in
            //print("value changed")
            //self?.sceneUpdated()
        }
        .store(in: &cancellables)
        
        
    }
    
    
    required init?(coder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    enum Error: Swift.Error {
        case commandQueuereationFailed
    }
    
    public func sceneUpdated() {
        print("scene data updated")
    }
    
    
    
    
    public func redraw() {
        let frameBuffDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: 512, height: 1024, mipmapped: false)
        frameBuffDesc.usage = MTLTextureUsage([.shaderRead, .shaderWrite])
        
        //this should be changed to a more suitable rgb format - no need for 4 channels
        let auxBuffDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: 512, height: 1024, mipmapped: false)
        auxBuffDesc.usage = MTLTextureUsage([.shaderWrite])
        
        if (self.texturePair == nil || reloadTextures){
            var src : MTLTexture = textureManager.loadTexture(path: SceneData.skybox)!
            var dst : MTLTexture = device.makeTexture(descriptor: frameBuffDesc)! //is this actually necessary? the kernel resets the destination texture
            print("sourcePair is not initialized")
            
            self.texturePair = (src, dst)
            reloadTextures = false
        }
        
        if (self.denoiserAuxilaries == nil)
        {
            let _albedo : MTLTexture = device.makeTexture(descriptor: auxBuffDesc)!
            let _normal : MTLTexture = device.makeTexture(descriptor: auxBuffDesc)!
            
            denoiserAuxilaries = (_albedo, _normal)
        }
        
        guard let source = self.texturePair?.source,
              let destination = self.texturePair?.destination,
              let commandBuffer = self.commandQueue.makeCommandBuffer()
        else { 
            print("something went wrong when setting uniforms and cmd buffer")
            return
        }
        
            //use the pipeline encoder to define a compute pipeline and fill command buffer
        self.encoder.sceneParams = SceneData
        self.encoder.encode(source: source, destination: destination, albedo: denoiserAuxilaries!.albedo, normal: denoiserAuxilaries!.normal, in: commandBuffer)
        
        //what will happen to the result of the compute kernel
        commandBuffer.addCompletedHandler { _ in
            guard let cgImage = try? self.textureManager.cgImage(from: destination)
            else {
                print("unable to make cg image in redraw function")
                return
            }
            
            if (self.SceneData.sampleCount == 80)
            {
                guard let pixArray = try? self.textureManager.colorValues(from: destination)
                        
                else {
                    print("could not get the color values in flat array")
                    return
                }
                print("got a color values array")
                
                let resultArray = self.SceneData.Denoiser.denoise(pixArray)
                
                let floatArray = Array(UnsafeBufferPointer(start: resultArray, count: 1024 * 512 * 3))
                
                DispatchQueue.main.async {
                    self.denoisedView = .init()
                    self.denoisedView?.image = .init(cgImage: self.textureManager.CGFromRGB(fromFloatValues: floatArray, width: 512, height: 1024)!)
                }
            }
            else {
                DispatchQueue.main.async {
                    self.imageView.image = .init(cgImage: cgImage)
                }
            }
            
            
            
            
        }
        commandBuffer.commit()
        
        
    }
    
}

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
    public let denoisedView : UIImageView
    private let commandQueue: MTLCommandQueue
    private let textureManager: TextureManager
    private var texturePair: (source: MTLTexture, destination: MTLTexture)?
    var cancellables: Set<AnyCancellable> = []
    
    
    init(device: MTLDevice, sceneData: SceneDataModel) throws{
        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let commandQueue = device.makeCommandQueue()          //make a command queue from the device
        else { throw Error.commandQueuereationFailed}
        self.device = device
        self.encoder = try .init(library: library)
        self.commandQueue = commandQueue
        self.textureManager = .init(device: device)
        self.SceneData = sceneData
        self.imageView = .init()
        self.denoisedView = .init()
        //super.init(nibName: nil, bundle: nil)
        
        sceneData.objectWillChange.sink {   [weak self] _ in
            print("value changed")
            self?.sceneUpdated()
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
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: 512, height: 1024, mipmapped: false)
        desc.usage = MTLTextureUsage([.shaderRead, .shaderWrite])
        //self.texturePair?.source = device.makeTexture(descriptor: desc)!
        //self.texturePair?.destination = device.makeTexture(descriptor: desc)!
        //var src : MTLTexture = device.makeTexture(descriptor: desc)!
        
        if (self.texturePair == nil || reloadTextures){
            var src : MTLTexture = textureManager.loadTexture(path: SceneData.skybox)!
            var dst : MTLTexture = device.makeTexture(descriptor: desc)!
            print("sourcePair is not initialized")
            
            self.texturePair = (src, dst)
            reloadTextures = false
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
        self.encoder.encode(source: source, destination: destination, in: commandBuffer)
        
        //what will happen to the result of the compute kernel
        commandBuffer.addCompletedHandler { _ in
            guard let cgImage = try? self.textureManager.cgImage(from: destination)
            else {
                print("unable to make cg image in redraw function")
                return
            }
            
            if (self.SceneData.sampleCount == 200)
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
                    self.denoisedView.image = .init(cgImage: self.textureManager.CGFromRGB(fromFloatValues: floatArray, width: 512, height: 1024)!)
                    
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
    
    /*
    @objc func handlePan(_ sender: UITapGestureRecognizer)
    {
        let translation = sender.translation(in: self.imageView)
        
        
    }
    */
    

    
    
}

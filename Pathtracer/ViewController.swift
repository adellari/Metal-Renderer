//
//  ViewController.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

import Foundation
import UIKit
import Metal

class ViewController: UIViewController {
    
    enum Error: Swift.Error {
        case commandQueuereationFailed
    }
    
    private let device: MTLDevice
    private let encoder: PipelineEncoder
    public let imageView: UIImageView
    private let commandQueue: MTLCommandQueue
    private let textureManager: TextureManager
    private var texturePair: (source: MTLTexture, destination: MTLTexture)?
    
    
    
    init(device: MTLDevice) throws{
        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let commandQueue = device.makeCommandQueue()
        else { throw Error.commandQueuereationFailed}
        self.device = device
        self.encoder = try .init(library: library)
        self.commandQueue = commandQueue
        self.textureManager = .init(device: device)
        self.imageView = .init()
        super.init(nibName: nil, bundle: nil)
        
    }
    
    
    required init?(coder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    public func redraw() {
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 400, height: 200, mipmapped: false)
        desc.usage = MTLTextureUsage([.shaderRead, .shaderWrite])
        //self.texturePair?.source = device.makeTexture(descriptor: desc)!
        //self.texturePair?.destination = device.makeTexture(descriptor: desc)!
        var src : MTLTexture = device.makeTexture(descriptor: desc)!
        var dst : MTLTexture = device.makeTexture(descriptor: desc)!
        
        self.texturePair = (src, dst)
        if self.texturePair == nil{
            print("sourcePair is not initialized")
        }
        
        guard let source = self.texturePair?.source,
              let destination = self.texturePair?.destination,
              let commandBuffer = self.commandQueue.makeCommandBuffer()
        else { 
            print("something went wrong when setting uniforms and cmd buffer")
            return
        }
        
        
        self.encoder.encode(source: source, destination: destination, in: commandBuffer)
        
        //what will happen to the result of the compute kernel
        commandBuffer.addCompletedHandler { _ in
            guard let cgImage = try? self.textureManager.cgImage(from: destination)
            else {
                print("unable to make cg image in redraw function")
                return
            }
            
            DispatchQueue.main.async {
                self.imageView.image = .init(cgImage: cgImage)
            }
        }
        commandBuffer.commit()
        
        
    }
    
    
}

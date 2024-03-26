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
    private let encoder: UniformsSetter
    private let imageView: UIImageView
    private let commandQueue: MTLCommandQueue
    private var texturePair: (source: MTLTexture, destination: MTLTexture)?
    
    
    init(device: MTLDevice) throws{
        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let commandQueue = device.makeCommandQueue()
        else { throw Error.commandQueuereationFailed}
        self.device = device
        self.commandQueue = commandQueue
        self.imageView = .init()
        super.init(nibName: nil, bundle: nil)
        
    }
    
    
    required init?(coder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    private func redraw() {
        guard let source = self.texturePair?.source,
              let destination = self.texturePair?.destination,
              let commandBuffer = self.commandQueue.makeCommandBuffer()
        else { return }
        
        self.encoder.encode(source: source, destination: destination, in: commandBuffer)
        
        commandBuffer.addCompletedHandler { _ in
            guard let cgImage = try? self.
        }
        
        
    }
    
    
}

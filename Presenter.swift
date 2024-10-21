//
//  Presenter.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 10/18/24.
//
import MetalKit
import Metal

class Presenter : NSObject
{
    var metalView : MTKView
    var viewController : ViewController?
    init(_device : MTLDevice, size: MTLSize)
    {
        self.metalView = MTKView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height), device: _device)
        super.init()
        
        self.metalView.framebufferOnly = false
        self.metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        
    }
    
    func draw(in view: MTKView)
    {
        guard let drawable = view.currentDrawable else { return }
        viewController!.redraw()
        
        let commandBuffer = viewController!.commandQueue.makeCommandBuffer()!
        let swapchainBlit = commandBuffer.makeBlitCommandEncoder()!
        
        swapchainBlit.copy(from: viewController!.texturePair!.destination, to: drawable.texture)
        swapchainBlit.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
}


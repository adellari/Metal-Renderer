//
//  TextureManager.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/27/24.
//

import Foundation
import MetalKit

final class TextureManager{
    
    
    enum Error: Swift.Error{
        case cgImageCreationFailed
        case textureCreationFailed
    }
    
    private let textureLoader: MTKTextureLoader
    
    init(device: MTLDevice) {
        self.textureLoader = .init(device: device)
    }
    
    func loadTexture(path: String) -> MTLTexture? {
        guard let image = UIImage(named: path)?.cgImage else {
            print("failed to create load image from path")
            return nil
        }
        
        do {
            let result = try texture(from:image)
            return result
        }
        catch {
            print("could not create MTLTexture from CGImage")
            return nil
        }
        
    }
    
    //create a metal texture from a cg image that has read/write enabled
    func texture(from cgImage: CGImage, usage: MTLTextureUsage = [.shaderRead, .shaderWrite]) throws -> MTLTexture{
        
        //do not make mipmaps, and make sure it's in linear space
        let textureOptions: [MTKTextureLoader.Option: Any] = [.textureUsage: NSNumber(value: usage.rawValue), .generateMipmaps: NSNumber(value: false), .SRGB: NSNumber(value: false)]
        
        //let textureOptions: [MTKTextureLoader.Option: Any] = [.textureUsage: NSNumber(value: (MTLTextureUsage.shaderRead.rawValue | MTLTextureUsage.sample.rawValue | MTLTextureUsage.shaderWrite.rawValue)), .generateMipmaps: NSNumber(value: false), .SRGB: NSNumber(value: false)]
        
        return try self.textureLoader.newTexture(cgImage: cgImage, options: textureOptions)
        
    }
    
    func matchingTexture(to texture: MTLTexture, usage: MTLTextureUsage? = nil) throws -> MTLTexture {
        
        let matchingDescriptor = MTLTextureDescriptor()
        matchingDescriptor.width = texture.width
        matchingDescriptor.height = texture.height
        matchingDescriptor.usage = usage ?? texture.usage
        matchingDescriptor.pixelFormat = .bgra8Unorm //Uhm why???
        matchingDescriptor.storageMode = texture.storageMode
        
        guard let matchingTexture = self.textureLoader.device.makeTexture(descriptor: matchingDescriptor)
        else {throw Error.textureCreationFailed}
        
        return matchingTexture
    }
    
    
    //create a CGImage from a metal texture
    func cgImage(from texture: MTLTexture) throws -> CGImage {
        let bytesPerRow = texture.width * 4 * 4 //rgba
        let length = bytesPerRow * texture.height
        
        let pixelBytes = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: MemoryLayout<Float32>.alignment)
        defer { pixelBytes.deallocate() }
        
        let destinationRegion = MTLRegion(origin: .init(x: 0, y: 0, z: 0), size: .init(width: texture.width, height: texture.height, depth: texture.depth))
        
        texture.getBytes(pixelBytes, bytesPerRow: bytesPerRow, from: destinationRegion, mipmapLevel: 0)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let hdrSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.floatComponents.rawValue)
        
        guard let data = CFDataCreate(nil, pixelBytes.assumingMemoryBound(to: Float.self), length),
              let dataProvider = CGDataProvider(data: data),
              let cgImage = CGImage(width: texture.width, height: texture.height, bitsPerComponent: 32, bitsPerPixel: 128, bytesPerRow: bytesPerRow, space: hdrSpace!, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                
        else {throw Error.cgImageCreationFailed}
        return cgImage
    }
    
}

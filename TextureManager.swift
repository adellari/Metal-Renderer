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
    
    //great HDR creation reference
    //https://github.com/Hi-Rez/Satin/blob/70f576550ecb7a8df8f3121a6a1a4c8939e9c4d8/Source/Utilities/Textures.swift#L114
    //create a CGImage from a metal texture
    func cgImage(from texture: MTLTexture) throws -> CGImage {
        let bytesPerRow = texture.width * 4 * 4 //rgba, with each being 4 bytes long
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
    
    func colorValues(from texture: MTLTexture) throws -> [Float] {
        let count = texture.width * texture.height * 4
        //var colValues = [Float](repeating: 0, count: count)
        
        let region = MTLRegion(origin: .init(x: 0, y: 0, z: 0), size: .init(width: texture.width, height: texture.height, depth: texture.depth))
        let bytesPerRow = texture.width * MemoryLayout<Float>.stride * 4
        
        let pixelBytes = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * texture.height, alignment: MemoryLayout<Float32>.alignment)
        
        defer { pixelBytes.deallocate() }
        
        texture.getBytes(pixelBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let colBufferPointer = pixelBytes.bindMemory(to: Float.self, capacity: count)
        let colBuffer = Array(UnsafeBufferPointer(start: colBufferPointer, count: count))
        
        return colBuffer
    }
    
    func CGFromRGB(fromFloatValues floatValues: [Float], width: Int, height: Int) -> CGImage? {
        guard floatValues.count == width * height * 3 else {
            print("Incorrect number of float values provided.")
            return nil
        }

        let dataSize = width * height * 3 * MemoryLayout<Float>.size
        let data = floatValues.withUnsafeBytes { Data($0) }
        let provider = CGDataProvider(data: data as CFData)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: CGBitmapInfo = [.byteOrder32Little, CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)]
        
        return CGImage(width: width, height: height, bitsPerComponent: 32, bitsPerPixel: 96, bytesPerRow: width * 3 * MemoryLayout<Float>.size, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
    
}

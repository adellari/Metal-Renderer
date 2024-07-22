//
//  MeshHandler.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 5/21/24.
//

import Foundation
import simd
import GLKit
import GLTFKit2

struct BVHNode
{
    var aabbMin : float3 = float3(Float.infinity);
    var aabbMax : float3 = float3(-Float.infinity);      //position of bounding box corners
    var lChild : Int16 = 0;
    //var rChild : UInt8 = 0;         //indices of left and right child nodes
    //var isLeaf : Bool = false;                  //is this node a leaf
    var firstPrim : Int16 = 0;
    var primCount : Int16 = 0;   //index of first enclosed triangle in tris array, and how many triangles in bvh
}

class BVHBuilder
{
    var tris : [Triangle]
    var N : Int
    var BVHTree : [BVHNode]
    var rootNodeIdx : Int
    var nodesUsed : Int
    var maxPackedTris : Int
    
    init(_tris: inout [Triangle])
    {
        N = _tris.count;
        tris = _tris;
        BVHTree = Array(repeating: BVHNode(), count: (2 * N) - 1)
        rootNodeIdx = 0
        nodesUsed = 1
        maxPackedTris = 0
    }
    
    func BuildBVH(tris : inout [Triangle])
    {
        
        for i in 0..<N {
            tris[i].centroid = (tris[i].v0 + tris[i].v1 + tris[i].v2) * 0.3333;
        }
        self.tris = tris;
        var Root : BVHNode = BVHTree[rootNodeIdx]
        Root.firstPrim = 0
        Root.primCount = Int16(N)
        BVHTree[rootNodeIdx] = Root
        
        UpdateNodeBounds(_nodeid: rootNodeIdx)
        
        Subdivide(nodeid: rootNodeIdx)
        self.BVHTree.removeSubrange(nodesUsed..<BVHTree.endIndex)
        print("maximum packed triangles: \(maxPackedTris)");
        /*
        var accountedTris = 0
        for i in 0..<BVHTree.count
        {
            var n = BVHTree[i]
            accountedTris += Int(n.primCount)
        }
        print(accountedTris)
        */
    }
    
    
    func UpdateNodeBounds(_nodeid : Int)
    {
        var node = BVHTree[_nodeid]
        node.aabbMin = float3(Float.infinity, Float.infinity, Float.infinity);
        node.aabbMax = float3(-Float.infinity, -Float.infinity, -Float.infinity);
        
        //print("node primitive count \(node.primCount)")
        for i in node.firstPrim..<(node.primCount + node.firstPrim)
        {
            var leafTri = tris[Int(i)]
            node.aabbMin = fmin(node.aabbMin, leafTri.v0);
            node.aabbMin = fmin(node.aabbMin, leafTri.v1);
            node.aabbMin = fmin(node.aabbMin, leafTri.v2);
            
            node.aabbMax = fmax(node.aabbMax, leafTri.v0);
            node.aabbMax = fmax(node.aabbMax, leafTri.v1);
            node.aabbMax = fmax(node.aabbMax, leafTri.v2);
        }
        BVHTree[_nodeid] = node
    }
    
    func Subdivide(nodeid: Int)
        {
            var node = BVHTree[nodeid];
            let extent : float3 = node.aabbMax - node.aabbMin;
            var axis : Int = 0;
            //print(extent)
            //determine which axis of triangles is the longest and set the plane to cut along that
            if (extent.y > extent.x) { axis = 1; }
            if (extent.z > extent[axis]) { axis = 2; }
            
            var splitPos : Float = node.aabbMin[axis] + extent[axis] * 0.5;
            
            var i = Int(node.firstPrim);
            var j = i + Int(node.primCount) - 1;
            //let concurrenceQueue = DispatchQueue(label: "com.pathtracer.swapQueue", attributes: .concurrent)
            while i <= j
            {
                if (tris[i].centroid[axis] <= splitPos)
                {
                    i+=1;
                }
                else
                {
                        tris.swapAt(i, j)
                        j -= 1;
                    
                }
                //print("swapping values, i: \(i), j: \(j)")
            }
            
            let leftCount = i - Int(node.firstPrim);
            if (leftCount == 0 || leftCount == node.primCount)  // the split's half has no or all the elements
            {
                if leftCount > maxPackedTris { maxPackedTris = leftCount; }
                return;
            }
            else 
            {
                let lChildId = nodesUsed;
                let rChildId = nodesUsed+1;
                
                nodesUsed += 2;
                //print(nodesUsed)
                node.lChild = Int16(lChildId);
                BVHTree[lChildId].firstPrim = node.firstPrim;
                BVHTree[lChildId].primCount = Int16(leftCount);
                BVHTree[rChildId].firstPrim = Int16(i);
                BVHTree[rChildId].primCount = node.primCount - Int16(leftCount);
                node.primCount = 0;
                
                UpdateNodeBounds(_nodeid: lChildId);
                UpdateNodeBounds(_nodeid: rChildId);
                
                Subdivide(nodeid: lChildId);
                Subdivide(nodeid: rChildId);
                BVHTree[nodeid] = node;
            }
            
            
        }

}

class MeshLoader
{
    var meshName : String?
    var asset : GLTFAsset?
    var t_albedo : MTLTexture?
    var t_normal : MTLTexture?
    var triangleOptionals : [TriangleOpt]?
    
    func loadModel(_ name: String, completion: @escaping (Bool) -> Void)
    {
        meshName = "models/"+name+"/scene";
        guard let assetURL = Bundle.main.url(forResource: meshName, withExtension: "gltf")
        else {
            print("Failed to find the 3D asset in bundle, relative path: \(meshName!)")
            completion(false)
            return
        }
        
        GLTFAsset.load(with: assetURL, options: [:]) { (progress, status, maybeAsset, maybeError, _) in
            DispatchQueue.main.async {
                
                if status == .complete {
                    self.asset = maybeAsset; //.meshes[0].primitives[0].attributes;
                    print("loaded 3d model");
                    completion(true)
                    return
                } else if let error = maybeError {
                    print("Failed to load glTF asset: \(error)")
                }
                completion(false)
                return
            }
            
        }
    }
    
    public func loadTextures() {
        print("texture count: \(self.asset!.textures.count)")
        //self.t_albedo = self.asset!.textures[0].
        //self.asset!.
        print(self.asset!.textures[0].name)
        print("images count: \(self.asset!.textures[0].description)")
    }
    
    public func loadTriangles() -> [Triangle] {
        var tris: [Triangle] = []
        var trisOpts : [TriangleOpt] = []
        //load the vertex positions
        //print(self.asset!.meshes.count)
        print(self.asset!.meshes[0].primitives.indices.count)
        //print(self.asset!.meshes[1].primitives.indices.count)
        for p in 0..<self.asset!.meshes.count {
            
            //read sequential vertex positions in
            var positions : [SIMD3<Float>] = []
            var normals : [SIMD3<Float>] = []
            var uvs : [SIMD2<Float>] = []
            var readIndices : [Int] = []
            let primitive = self.asset!.meshes[p].primitives[0]
            var positionPtr : UnsafeRawBufferPointer?
            var normalPtr : UnsafeRawBufferPointer?
            var uvPtr : UnsafeRawBufferPointer?
            var vertexPositions : Data?
            
           if let _positions = primitive.copyPackedVertexPositions() {
               vertexPositions = _positions
                positionPtr = _positions.withUnsafeBytes { bytes in
                    return UnsafeRawBufferPointer(start: bytes.baseAddress, count: bytes.count)
                }
            }
            
            if let _normals = primitive.copyPackedVertexNormals() {
                normalPtr = _normals.withUnsafeBytes { bytes in
                    return UnsafeRawBufferPointer(start: bytes.baseAddress, count: bytes.count)
                }
            }
            
            if let _uvs = primitive.copyPackedVertexUVs() {
                uvPtr = _uvs.withUnsafeBytes { bytes in
                    return UnsafeRawBufferPointer(start: bytes.baseAddress, count: bytes.count)
                }
            }
            
            for i in 0..<vertexPositions!.count / (MemoryLayout<Float>.stride * 3) {
                let position = positionPtr!.baseAddress!
                    .advanced(by: MemoryLayout<Float>.stride * 3 * i)
                    .assumingMemoryBound(to: Float.self)
                let normal = normalPtr!.baseAddress!
                    .advanced(by: MemoryLayout<Float>.stride * 3 * i)
                    .assumingMemoryBound(to: Float.self)
                
                let uv = uvPtr!.baseAddress!
                    .advanced(by: MemoryLayout<Float>.stride * 2 * i)
                    .assumingMemoryBound(to: Float.self)
                
                let xp = position[0]
                let yp = position[1]
                let zp = position[2]
                
                let xn = normal[0]
                let yn = normal[1]
                let zn = normal[2]
                
                positions.append(SIMD3<Float>(xp, yp, zp))
                normals.append(SIMD3<Float>(xn, yn, zn))
                uvs.append(SIMD2<Float>(uv[0], uv[1]))
            }
            
            /*
            if let vertexNormals = primitive.copyPackedVertexNormals() {
                vertexNormals.withUnsafeBytes { normalsPtr in
                    for i in 0..<vertexNormals.count / (MemoryLayout<Float>.stride * 3) {
                        let normal = normalsPtr.baseAddress!
                            .advanced(by: MemoryLayout<Float>.stride * 3 * i)
                            .assumingMemoryBound(to: Float.self)

                        let x = normal[0]
                        let y = normal[1]
                        let z = normal[2]
                        normals.append(SIMD3<Float>(x, y, z))
                    }
                }
            }
            */
            //print("length of uvs: \(uvs.count)")
            print(primitive.indices!.count / 3)
            print("vertex positions count: \(positions.count), normals count: \(normals.count), uvs count: \(uvs.count)" )
            //Get our vertex indices (3x the number of triangles we'll create)
            if let indices = primitive.indices {
                
                //Read our uint16 index set from the bufferview
                let uint16Data = indices.bufferView!.buffer.data!.withUnsafeBytes { $0.bindMemory(to: UInt16.self) }
                for i in stride(from: 0, to: indices.count * 2, by: MemoryLayout<UInt16>.stride) {
                    var index = Int(uint16Data[i])
                    readIndices.append(index)
                }
                
                
                //Create triangles based on our indices array
                for i in 0..<readIndices.count / 3 {
                    let a = readIndices[i * 3]
                    let b = readIndices[i * 3 + 1]
                    let c = readIndices[i * 3 + 2]
                    
                    let _v0 = positions[a]
                    let _v1 = positions[b]
                    let _v2 = positions[c]
                    
                    let _uv0 = uvs[a]
                    let _uv1 = uvs[b]
                    let _uv2 = uvs[c]
                    
                    let _norm0 = normals[a]
                    let _norm1 = normals[b]
                    let _norm2 = normals[c]
                    
                    let tri = Triangle(v0: _v0, v1: _v1, v2: _v2)
                    let triOpt = TriangleOpt(uv0: _uv0, uv1: _uv1, uv2: _uv2, n0: _norm0, n1: _norm1, n2: _norm2)
                    
                    tris.append(tri)
                    trisOpts.append(triOpt)
                }
            }
        }

        print("loaded \(tris.count) triangle primitives")
        return tris
    }
    
}





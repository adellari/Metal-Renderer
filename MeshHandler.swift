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
    var aabbMin : float3 = float3();
    var aabbMax : float3 = float3();      //position of bounding box corners
    var lChild : UInt8 = 0;
    //var rChild : UInt8 = 0;         //indices of left and right child nodes
    //var isLeaf : Bool = false;                  //is this node a leaf
    var firstPrim : UInt8 = 0;
    var primCount : UInt8 = 0;   //index of first enclosed triangle in tris array, and how many triangles in bvh
}

class BVHBuilder
{
    var tris : [Triangle]
    var N : Int
    var BVHTree : [BVHNode]
    var rootNodeIdx : Int
    var nodesUsed : Int
    
    init(_tris: inout [Triangle])
    {
        N = _tris.count;
        tris = _tris;
        BVHTree = Array(repeating: BVHNode(), count: (2 * N) - 1)
        rootNodeIdx = 0
        nodesUsed = 1
    }
    
    func BuildBVH(tris : inout [Triangle])
    {
        /*
         let N = tris.count;
         var rootNodeIdx : Int = 0
         var nodesUsed : Int = 1
         var BVHTree : [BVHNode] = Array(repeating: BVHNode(), count: (2 * N) - 1)
         */
        
        for i in 0..<N {
            tris[i].centroid = (tris[i].v0 + tris[i].v1 + tris[i].v2) * 0.3333;
        }
        
        var Root : BVHNode = BVHTree[rootNodeIdx]
        Root.firstPrim = 0
        Root.primCount = UInt8(N)
        UpdateNodeBounds(nodeid: rootNodeIdx)
        
        Subdivide(nodeid: rootNodeIdx)
    }
    
    
    func UpdateNodeBounds(nodeid : Int)
    {
        var node = BVHTree[nodeid]
        node.aabbMin = float3(Float.infinity, Float.infinity, Float.infinity);
        node.aabbMax = float3(-Float.infinity, -Float.infinity, -Float.infinity);
        
        for i in node.firstPrim..<node.primCount
        {
            var leafTri = tris[Int(i)]
            node.aabbMin = fmin(node.aabbMin, leafTri.v0);
            node.aabbMin = fmin(node.aabbMin, leafTri.v1);
            node.aabbMin = fmin(node.aabbMin, leafTri.v2);
            
            node.aabbMax = fmax(node.aabbMax, leafTri.v0);
            node.aabbMax = fmax(node.aabbMax, leafTri.v1);
            node.aabbMax = fmax(node.aabbMax, leafTri.v2);
        }
    }
    
    func Subdivide(nodeid: Int)
    {
        var node = BVHTree[nodeid];
        let extent : float3 = node.aabbMax - node.aabbMin;
        var axis : Int = 0;
        
        //determine which axis of triangles is the longest and set the plane to cut along that
        if (extent.y > extent.x) { axis = 1; }
        if (extent.z > extent[axis]) { axis = 2; }
        
        var splitPos : Float = node.aabbMin[axis] + extent[axis] * 0.5;
        
        var i = Int(node.firstPrim);
        var j = i + Int( node.primCount - 1);
        
        while i <= j
        {
            if (tris[i].centroid[axis] < splitPos)
            {
                i+=1;
            }
            else
            {
                swap(&tris[i], &tris[j]);
                j -= 1;
            }
        }
        
        let leftCount = i - Int(node.firstPrim);
        if (leftCount == 0 || leftCount == node.primCount)  // the split's half has no or all the elements
        {
            return;
        }
        
        let lChildId = nodesUsed+1;
        let rChildId = nodesUsed+2;
        
        nodesUsed += 2;
        
        node.lChild = UInt8(lChildId);
        BVHTree[lChildId].firstPrim = node.firstPrim;
        BVHTree[lChildId].primCount = UInt8(leftCount);
        BVHTree[rChildId].firstPrim = UInt8(i);
        BVHTree[rChildId].primCount = node.primCount - UInt8(leftCount);
        node.primCount = 0;
        
        UpdateNodeBounds(nodeid: lChildId);
        UpdateNodeBounds(nodeid: rChildId);
        
        Subdivide(nodeid: lChildId);
        Subdivide(nodeid: rChildId);
    }
}

class MeshLoader
{
    var meshName : String?;
    var asset : GLTFAsset?;
    
    /*
    init(_ name: String)
    {
        meshName = name
        loadModel()
    }
    */
    
    func loadModel(_ name: String, completion: @escaping (Bool) -> Void)
    {
        meshName = "models/"+name;
        guard let assetURL = Bundle.main.url(forResource: meshName, withExtension: "gltf")
        else {
            print("Failed to find the 3D asset in bundle")
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
    
    public func loadTriangles() -> [Triangle] {
        var tris: [Triangle] = []
        var positions : [SIMD3<Float>] = []
        let primitive = self.asset!.meshes[0].primitives[0]
        if let vertexPositions = primitive.copyPackedVertexPositions() {
            vertexPositions.withUnsafeBytes { positionPtr in
                print(vertexPositions.count)
                for i in 0..<vertexPositions.count / (MemoryLayout<Float>.stride * 3) {
                    let position = positionPtr.baseAddress!
                        .advanced(by: MemoryLayout<Float>.stride * 3 * i)
                        .assumingMemoryBound(to: Float.self)

                    let x = position[0]
                    let y = position[1]
                    let z = position[2]
                    positions.append(SIMD3<Float>(x, y, z))
                    //let tri = Triangle(v0: x, v1: y, v2: z)
                    print("\(x) \(y) \(z)")
                }
            }
        }
        
        for i in stride(from: 0, to: positions.count, by: 3) {
            tris.append(Triangle(v0: positions[i], v1: positions[i+1], v2: positions[i+2]))
        }
        print("loaded \(tris.count) triangle primitives")
        return tris
    }
    
}





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
        //self.BVHTree = BVHTree
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
                if (tris[i].centroid[axis] < splitPos)
                {
                    i+=1;
                }
                else
                {
                        tris.swapAt(i, j)
                        j -= 1;
                    
                }
            }
            
            let leftCount = i - Int(node.firstPrim);
            if (leftCount == 0 || leftCount == node.primCount)  // the split's half has no or all the elements
            {
                return;
            }
            else 
            {
                let lChildId = nodesUsed;
                let rChildId = nodesUsed+1;
                
                nodesUsed = nodesUsed + 2;
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
    
    public func loadTriangles() -> [Triangle] {
        var tris: [Triangle] = []
        var positions : [SIMD3<Float>] = []
        var readIndices : [Int] = []
        //load the vertex positions
        //print(self.asset!.meshes.count)
        //print(self.asset!.meshes[0].primitives.count)
        for p in 0..<self.asset!.meshes.count {
            let primitive = self.asset!.meshes[p].primitives[0]
            if let vertexPositions = primitive.copyPackedVertexPositions() {
                vertexPositions.withUnsafeBytes { positionPtr in
                    //print(primitive.indices!.count)
                    for i in 0..<vertexPositions.count / (MemoryLayout<Float>.stride * 3) {
                        let position = positionPtr.baseAddress!
                            .advanced(by: MemoryLayout<Float>.stride * 3 * i)
                            .assumingMemoryBound(to: Float.self)

                        let x = position[0]
                        let y = position[1]
                        let z = position[2]
                        positions.append(SIMD3<Float>(x, y, z))
                        //let tri = Triangle(v0: x, v1: y, v2: z)
                        //print("\(x) \(y) \(z)")
                    }
                }
            }
            print(primitive.indices!.count / 3)
            //Get our vertex indices (3x the number of triangles we'll create)
            if let indices = primitive.indices {
                
                //print(indices.bufferView!.buffer.data)
                let uint16Data = indices.bufferView!.buffer.data!.withUnsafeBytes { $0.bindMemory(to: UInt16.self) }
                
                for i in stride(from: 0, to: indices.count * 2, by: MemoryLayout<UInt16>.stride) {
                    var index = Int(uint16Data[i])
                    //print(index)
                    readIndices.append(index)
                }
                //Create triangles based on the vertex and indices
                for i in 0..<readIndices.count / 3 {
                    let x = positions[readIndices[i * 3]]
                    let y = positions[readIndices[i * 3 + 1]]
                    let z = positions[readIndices[i * 3 + 2]]
                    tris.append(Triangle(v0: x, v1: y, v2: z))
                }
            }
        }
        
        
        print("loaded \(tris.count) triangle primitives")
        return tris
    }
    
}





//
//  MeshHandler.swift
//  Pathtracer
//
//  Created by Adellar Irankunda on 5/21/24.
//

import Foundation
import simd
import GLKit

struct BVHNode
{
    var aabbMin : float3 = float3();
    var aabbMax : float3 = float3();      //position of bounding box corners
    var lChild : UInt8 = 0;
    var rChild : UInt8 = 0;         //indices of left and right child nodes
    var isLeaf : Bool = false;                  //is this node a leaf
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
        
    
    }
}


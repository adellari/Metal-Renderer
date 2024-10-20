//
//  Pathtracer.metal
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

#include <metal_stdlib>
using namespace metal;
#define PI 3.1415926535
#define EPSILON 1e-8

constant bool deviceSupportsNonuniformThreadgroups [[function_constant(0)]];

constexpr sampler textureSampler(filter::linear, address::repeat);

struct CameraParams {
    float4x4 worldToCamera;
    float4x4 projectionInv;
    float3 cameraPosition;
    float focalLength;
    float aperture;
    float dummy;
};

struct Ray {
    float3 direction;
    float3 origin;
    float3 energy;
    float seed;
    float2 jitter;
};

struct RayHit {
    float3 position;
    float3 normal;
    float3 albedo;
    float3 specular;
    float3 emission;
    float3 refractionColor;
    float distance;
    float smoothness;
    float IOR;
    float refractionChance;
    float refractionSmoothness;
    bool inside;
};

struct Sphere {
    float4 point;       //position, scale
    float3 albedo;
    float3 specular;
    float4 emission;
    float3 refractionColor;
    float smoothness;
    float refractiveIndex;
    float refractionRoughness;
    float refractionChance;
};

struct Triangle {
    float3 v0;
    float3 v1;
    float3 v2;
    float3 centroid; //centroid
};

struct VertexProperties {
    float2 uv0;
    float2 uv1;
    float2 uv2;
    float3 normal0;
    float3 normal1;
    float3 normal2;
};

struct Surface {
    short albedo;
    short normal;
    short material;
};

struct BVHNode {
    float3 aabbMin;
    float3 aabbMax;
    short lChild;
    short firstPrim;
    short primCount;
};

bool any(float3 val)
{
    return (val.x * val.y * val.z) > 0.001f;
}

float3 channelSwap(float3 col)
{
    return float3(col.b, col.g, col.r);
}

inline uint Float3toUInt8(float3 col)
{
    uint r8 = uint(col.r * 255.f + 0.5f);
    uint g8 = uint(col.g * 255.f + 0.5f);
    uint b8 = uint(col.b * 255.f + 0.5f);
    
    return (r8 << 16) | (g8 << 8) | b8;
}

inline int ColtoSInt8(float3 norm)
{
    
    int r8 = int(norm.r * 255.f + 0.5f) - 128;
    int g8 = int(norm.g * 255.f + 0.5f) - 128;
    int b8 = int(norm.b * 255.f + 0.5f) - 128;
    
    return (r8 << 16) | (g8 << 8) | b8;
}

inline float3 SInt8toCol(int col)
{
    float s = 1.f / 128.f;
    int r = (col >> 16) & 127;
    int g = (col >> 8) & 127;
    int b = col & 127;
    
    r *= s;
    g *= s;
    g *= s;
    
    return float3(r, g, b);
}
inline int NormtoSInt8(float3 norm)
{
    int signR = norm.r / abs(norm.r);
    int signG = norm.g / abs(norm.g);
    int signB = norm.b / abs(norm.b);
    
    int r8 = int(norm.r * 127.f + 0.5f * signR);
    int g8 = int(norm.g * 127.f + 0.5f * signG);
    int b8 = int(norm.b * 127.f + 0.5f * signB);
    
    return (r8 << 16) | (g8 << 8) | b8;
}

inline float3 RGB8toRGB32F( uint c )
{
    float s = 1 / 256.0f;
    int r = (c >> 16) & 255;  // extract the red byte
    int g = (c >> 8) & 255;   // extract the green byte
    int b = c & 255;          // extract the blue byte
    return float3( r * s, g * s, b * s );
}

float energy(float3 color)
{
    return(dot(color, 1.f / 3.f));
}

float sdot(float3 v1, float3 v2, float f = 1.f)
{
    return saturate(dot(v1, v2) * f);
}

float FresnelReflectAmount(float n1, float n2, float3 normal, float3 incident, float f0, float f90)
{
    //Schlick Approximation
    float r0 = (n1 - n2) / (n1 + n2);
    r0 *= r0;
    float cosx = -dot(normal, incident);
    
    if (n1 > n2)
    {
        float n = n1/n2;
        float sinT2 = n*n*(1.f - cosx * cosx);
        
        //total internal reflection
        if (sinT2 > 1.f)
            return f90;
        
        cosx = sqrt(1.f - sinT2);
    }
    
    float x = 1.f-cosx;
    float ret = r0+(1.f-r0)*x*x*x*x*x;
    
    //return a mix between the 90 and 0 deg reflections
    return mix(f0, f90, ret);
    
}

float SmoothnessToAlpha(float s)
{
    return pow(1000.f, s);
}

float rand(thread float* _Seed, float2 Jitter)
{
    float result = fract(sin(*_Seed / 100.f * dot(Jitter.yx, float2(12.9898f, 78.233f))) * 43758.5453f);
    *_Seed += 1.0f;
    return result;
}

float rand(float _Seed, float2 Jitter)
{
    float result = fract(sin(_Seed / 100.f * dot(Jitter.xy, float2(12.9898f, 78.233f))) * 43758.5453f);
    //*_Seed += 1.0f;
    return result;
}

float rand2(int x, int y, int z)
{
    int seed = x + y * 57 + z * 241;
    seed= (seed<< 13) ^ seed;
    return (( 1.0 - ( (seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

float2 CartesianToSpherical(float3 dir)
{
    float theta = acos(dir.y) / -PI;
    float phi = atan2(dir.x, -dir.z) / -PI * 0.5f;
    return float2(theta, phi);
}

float3x3 GetTangentSpace(float3 normal)
{
    float3 helper = float3(1, 0, 0);
    
    if(abs(normal.x) > 0.99f)
        helper = float3(0, 0, 1);
    
    float3 tangent = normalize(cross(normal, helper));  //tangent
    float3 binormal = normalize(cross(normal, tangent));  //bitangent
    
    return float3x3(tangent, binormal, normal);
}

float3 SampleHemisphere(float3 normal, float alpha, float seed, float2 jitter)
{
    float cosTheta = pow(rand(seed, jitter), 1.f / (alpha + 1.f));
    seed += 1.f;
    float sinTheta = sqrt(1.f - cosTheta * cosTheta);
    float phi = 2 * PI * rand(seed, jitter);
    
    float3 cartesianSpace = float3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
    return GetTangentSpace(normal) * cartesianSpace;    //MATRIX MULTIPLICATION ORDER   MATTERS
}

float3 SampleHemisphere(float3 normal, float alpha, int3 randSeeds)
{
    float cosTheta = pow(rand2(randSeeds.x, randSeeds.y, randSeeds.z), 1.f / (alpha + 1.f));
    randSeeds += 1323;
    float sinTheta = sqrt(1.f - cosTheta * cosTheta);
    float phi = 2 * PI * rand2(randSeeds.x, randSeeds.y, randSeeds.z);
    
    float3 cartesianSpace = float3(cos(phi) * sinTheta, sin(phi) * sinTheta, cosTheta);
    return GetTangentSpace(normal) * cartesianSpace;    //MATRIX MULTIPLICATION ORDER   MATTERS
}


Ray CreateRay(float3 origin, float3 direction, float2 clipPos, float seed){
    Ray ray;
    ray.origin = origin;
    ray.direction = direction;
    ray.energy = float3(1.f, 1.f, 1.f);
    ray.seed = seed;
    ray.jitter = (clipPos + 1.f) / 2.f;
    return ray;
}

Ray CreateCameraRay(float2 screenPos, constant CameraParams* cam)
{
    Ray ray;
    float3 origin = (float4(cam->cameraPosition, 1) * cam->worldToCamera).xyz; //z axis and x axis are reversed here?
    float3 dir = (float4(screenPos, 0, 1) * cam->projectionInv).xyz;
    
    dir = normalize((float4(dir, 0) * cam->worldToCamera).xyz);
    ray = CreateRay(origin, dir, screenPos, cam->dummy);
    
    return ray;
}

Ray CreateSecondaryRay(float2 screenPos, constant CameraParams* cam, float3 fPoint, float2 apertureOffset)
{
    Ray ray;
    float3 origin = (float4(cam->cameraPosition, 1) * cam->worldToCamera).xyz; //z axis and x axis are reversed here?
    float3 dir = (float4(( (apertureOffset) + screenPos), 0, 1) * cam->projectionInv).xyz;
    //float3 dir = fPoint - offsetPos;
    
    dir = normalize((float4(dir, 0) * cam->worldToCamera).xyz);
    
    dir = normalize(fPoint - (origin + dir));
    ray = CreateRay(origin, dir, screenPos, cam->dummy);
    
    return ray;
}

RayHit CreateRayHit(){
    RayHit hit;
    hit.distance = INFINITY;
    hit.position = float3(0.f, 0.f, 0.f);
    hit.albedo = float3(0.f, 0.f, 0.f);
    hit.specular = float3(1.f, 1.f, 1.f);
    hit.normal = float3(0.f, 0.f, 0.f);
    hit.refractionColor = float3(0.f, 0.f, 0.f);
    hit.IOR = 1.f;
    hit.refractionChance = 0.f;
    hit.refractionSmoothness = 0.f;
    hit.smoothness = 0.f;
    hit.emission = 0.f;
    hit.inside = false;
    return hit;
};

void IntersectGroundPlane(Ray ray, thread RayHit* hit)
{
    float t = -ray.origin.y / ray.direction.y;
    
    if(t > 0.f && t < hit->distance){
        hit->distance = t;
        hit->position = t * ray.direction + ray.origin;
        hit->normal = float3(0.f, 1.f, 0.f);
        hit->albedo = float3(0.5f, 0.5f, 0.5f);
        hit->specular = float3(0.1f, 0.1f, 0.1f);
        hit->emission = 0.f;
        hit->smoothness = 3.f;
    }
}

void IntersectSphere(Ray ray, thread RayHit* hit, Sphere sphere) {
    float3 toOrigin = ray.origin - sphere.point.xyz;
    
    float p1 = dot(toOrigin, ray.direction);
    float c = dot(toOrigin, toOrigin) - sphere.point.w * sphere.point.w;
    
    if (c > 0.f && p1 > 0.f)
        return;
    
    float p2sqr = p1 * p1 - c;
    
    if (p2sqr < 0.f)
        return;
    
    float dist = -p1 - sqrt(p2sqr);
    bool inside = false;
    
    if (dist < 0.f)
    {
        inside = true;
        dist = -p1 + sqrt(p2sqr);
    }
    
    if (dist > 0.f && dist < hit->distance)
    {
        hit->distance = dist;
        hit->position = ray.origin + (ray.direction * dist);
        hit->inside = inside;
        hit->normal = normalize(hit->position - sphere.point.xyz) * (inside ? -1.f : 1.f);
        hit->albedo = sphere.albedo;
        hit->emission = sphere.emission.rgb * sphere.emission.a;
        hit->specular = sphere.specular;
        hit->smoothness = sphere.smoothness;
        hit->refractionChance = sphere.refractionChance;
        hit->refractionColor = sphere.refractionColor;
        hit->refractionSmoothness = sphere.refractionRoughness;
        hit->IOR = sphere.refractiveIndex;
    }
    
}

float IntersectAABB(Ray ray, RayHit hit, float3 bMin, float3 bMax)
{
    float tx1 = (bMin.x - ray.origin.x) / ray.direction.x, tx2 = (bMax.x - ray.origin.x) / ray.direction.x;
    float tmin = min( tx1, tx2 ), tmax = max( tx1, tx2 );
    float ty1 = (bMin.y - ray.origin.y) / ray.direction.y, ty2 = (bMax.y - ray.origin.y) / ray.direction.y;
    tmin = max( tmin, min( ty1, ty2 ) ), tmax = min( tmax, max( ty1, ty2 ) );
    float tz1 = (bMin.z - ray.origin.z) / ray.direction.z, tz2 = (bMax.z - ray.origin.z) / ray.direction.z;
    tmin = max( tmin, min( tz1, tz2 ) ), tmax = min( tmax, max( tz1, tz2 ) );
    
    if (tmax >= tmin && tmax > 0 && tmin < hit.distance)
        return tmin;
    else return INFINITY;
}

float IntersectBB(Ray ray, RayHit hit, float3 bbMin, float3 bbMax)
{
    float3 invDir = 1. / ray.direction;
    float3 tMin = (bbMin - ray.origin) * invDir;
    float3 tMax = (bbMax - ray.origin) * invDir;
    float3 t1 = min(tMin, tMax);
    float3 t2 = max(tMin, tMax);
    
    float distFar = min(min(t2.x, t2.y), t2.z);
    float distNear = max(max(t1.x, t1.y), t1.z);
    
    bool didHit = distNear <= distFar && distFar > 0;
    return didHit? distNear : INFINITY;
}

//The Tomas Akenine-Moller and Ben Trumbone 1997 fast triangle intersection algorithm
//https://fileadmin.cs.lth.se/cs/Personal/Tomas_Akenine-Moller/pubs/raytri_tam.pdf
//out params: t - how far along ray.direction we hit the triangle
//          u, v, w are barycentrinc coords where w = 1 - u - v
//barycentric equation for a point on a triangle is P = wA + uB + vC, where ABC are the vertices
bool IntersectTriangle(Ray ray, float3 v0, float3 v1, float3 v2, thread float* t, thread float* u, thread float* v)
{
    //find edges sharing the same vertex
    float3 edge1 = v1 - v0;
    float3 edge2 = v2 - v0;
    
    //calculate the determinant
    float3 pvec = cross(ray.direction, edge2);
    
    float det = dot(edge1, pvec);
    
    if (abs(det) < EPSILON)
        return false;
    
    //if(det < EPSILON && det > -EPSILON)
      //  return false;
    
    float inv_det = 1.f / det;
    
    float3 tvec = ray.origin - v0;
    *u = dot(tvec, pvec) * inv_det;
    if(*u < 0.f || *u > 1.f)
        return false;
    
    float3 qvec = cross(tvec, edge1);
    
    *v = dot(ray.direction, qvec) * inv_det;
    if(*v < 0.f || *u + *v > 1.f)
        return false;
    
    *t = dot(edge2, qvec) * inv_det;
    return true;
}

void IntersectBVH(Ray ray, thread RayHit* rh, constant BVHNode *BVHTree, constant Triangle *tris, int nodeId)
{
    int traverseStack[400];

    int stackId = 0;
    traverseStack[stackId] = 0;
    stackId++;
     
    while (stackId > 0)
    {
        stackId--;
        nodeId = traverseStack[stackId];
        BVHNode node = BVHTree[nodeId];
        float hitDist = IntersectBB(ray, *rh, node.aabbMin, node.aabbMax);
        if ( hitDist == INFINITY) continue;
        
        if (node.primCount == 0)
        {
            
            float dist1 = IntersectAABB(ray, *rh, BVHTree[node.lChild].aabbMin, BVHTree[node.lChild].aabbMax);
            float dist2 = IntersectAABB(ray, *rh, BVHTree[node.lChild + 1].aabbMin, BVHTree[node.lChild + 1].aabbMax);
            
            if (dist1 < dist2)
            {
                if (dist2 < rh->distance)
                    traverseStack[stackId++] = node.lChild + 1; //far
                if (dist1 < rh->distance)
                    traverseStack[stackId++] = node.lChild ;    //near
            }
            else
            {
                if (dist1 < rh->distance)
                    traverseStack[stackId++] = node.lChild; //far
                if (dist2 < rh->distance)
                    traverseStack[stackId++] = node.lChild + 1; //near
            }
            
        }
        else
        {
            
            for (int a = node.firstPrim; a < (node.firstPrim + node.primCount); a++)
            {
                Triangle tri = tris[a];
                float3 v0 = tri.v0;
                float3 v1 = tri.v1;
                float3 v2 = tri.v2;
                float t, u, v;
                
                
                if(IntersectTriangle(ray, v0, v1, v2, &t, &u, &v))
                {
                    
                    if (t > 0 && t < rh->distance)
                    {
                        rh->distance = t;
                        rh->position = ray.origin + ray.direction * t;
                        rh->normal = normalize(cross(v1 - v0, v2 - v0));
                        rh->albedo = float3(1.f, 0.f, 0.f) * 0.1f;
                        rh->specular = 0.3f * float3(1.f, 0.4f, 0.2f);
                        rh->refractionColor = float3(0.f, 0.f, 0.f);
                        rh->emission = 0.f;
                        rh->smoothness = 0.9f;
                        rh->inside = false;
                        
                    }
                    
                }
            }
            continue;
        }
        
    }
    
    
}

/*
void IntersectBVHDebug(Ray ray, thread RayHit* rh, constant BVHNode *BVHTree, constant Triangle *tris, int nodeId)
{
    int traverseStack[200];

    int stackId = 0;
    traverseStack[stackId] = 0;
    stackId++;
     
    while (stackId > 0)
    {
        stackId--;
        nodeId = traverseStack[stackId];
        BVHNode node = BVHTree[nodeId];
        float hitDist = IntersectBB(ray, *rh, node.aabbMin, node.aabbMax);
        if ( hitDist >= rh->distance) continue;
        
        if (node.primCount == 0)
        {
            float dist1 = IntersectAABB(ray, *rh, BVHTree[node.lChild].aabbMin, BVHTree[node.lChild].aabbMax);
            float dist2 = IntersectAABB(ray, *rh, BVHTree[node.lChild + 1].aabbMin, BVHTree[node.lChild + 1].aabbMax);
            
            if (dist1 < dist2)
            {
                if (dist2 < rh->distance)
                    traverseStack[stackId++] = node.lChild + 1; //far
                if (dist1 < rh->distance)
                    traverseStack[stackId++] = node.lChild ;    //near
            }
            else
            {
                if (dist1 < rh->distance)
                    traverseStack[stackId++] = node.lChild; //far
                if (dist2 < rh->distance)
                    traverseStack[stackId++] = node.lChild + 1; //near
            }
            
        }
        else
        {
            
            rh->distance = node.primCount / 16.0;
            rh->albedo = 0.1f;
            rh->specular = 0.65f * float3(1.f, 0.4f, 0.2f);
            rh->refractionColor = float3(0.f, 0.f, 0.f);
            rh->emission = 0.f;
            rh->smoothness = 0.9f;
            rh->inside = false;
        }
        
    }
    
    
}
*/

RayHit Trace(Ray ray, Sphere s3, constant Triangle *triangles, constant BVHNode *BVHTree)
{
    
    RayHit hit = CreateRayHit();
    
    Sphere s;
    s.albedo = float3(0.1f, 0.42f, 0.93f);
    s.specular = float3(0.3f, 1.f, 1.f);
    //s.specular = 0.1f;
    s.emission = 0.f;
    s.smoothness = 3.f;
    s.refractionColor = 0.3f;
    s.refractiveIndex = 1.8f;
    s.refractionChance = 0.8f;
    s.point = float4(0, 0.4f, 0.2f, 1.3f);
    
    Sphere s5;
    s5.albedo = s3.albedo;//float3(0.2f, 0.2f, 1.f);
    s5.specular = float3(0.2f, 0.2f, 1.f);
    s5.emission = s3.emission * 30.f; //float3(1.f, 4.f, 20.f); //float3(1.f, 4.f, 20.f)
    s5.smoothness = 0.9f;
    s5.refractionColor = 0.f;
    s5.refractiveIndex = 0.f;
    s5.refractionChance = 0.f;
    s5.point = float4(2.2f, 1.3f, 0.2f, 0.15f);
    
    Sphere s4;
    s4.albedo = s3.albedo;//float3(0.2f, 0.2f, 1.f);
    s4.specular = float3(0.2f, 0.2f, 1.f);
    s4.emission = s3.emission * 30.f; //float3(1.f, 4.f, 20.f); //float3(1.f, 4.f, 20.f)
    s4.smoothness = 0.9f;
    s4.refractionColor = 0.f;
    s4.refractiveIndex = 0.f;
    s4.refractionChance = 0.f;
    s4.point = float4(-2.2f, 1.3f, 0.2f, 0.15f);
    
    /*
    Sphere s1;
    s1.albedo = s3.albedo;//float3(0.2f, 0.2f, 1.f);
    s1.specular = float3(0.2f, 0.2f, 1.f);
    s1.emission = s3.emission * 15.f; //float3(1.f, 4.f, 20.f); //float3(1.f, 4.f, 20.f)
    s1.smoothness = 0.9f;
    s1.refractionColor = 0.f;
    s1.refractiveIndex = 0.f;
    s1.refractionChance = 0.f;
    s1.point = float4(-0.7f, .4f, 2.2f, 0.15f);
    
    
    
    Sphere s2;      //stays at origin
    s2.albedo = 1.f;
    s2.specular = 0.1f;
    s2.emission = 0.f;
    s2.smoothness = 0.3f;
    s2.refractionColor = 0.f;
    s2.refractiveIndex = 0.f;
    s2.refractionChance = 0.f;
    s2.point = float4(0.f, 0.5f, 2.2f, 0.40f);
    
    
    
    //IntersectGroundPlane(ray, &hit);
    s3.emission = 0.f;
    
    IntersectSphere(ray, &hit, s3);
    
    IntersectSphere(ray, &hit, s4);
    IntersectSphere(ray, &hit, s5);
    */
    IntersectSphere(ray, &hit, s);
    IntersectSphere(ray, &hit, s5);
    IntersectSphere(ray, &hit, s4);
    IntersectBVH(ray, &hit, BVHTree, triangles, 0);
    /*
    float3 v0 = float3(-0.694, 0.)//float3(2.145, 0.0, 0.0);
    float3 v1 = float3(-0.712, 0.374, 0.0);//float3(2.084, 0.354, 0.0);
    float3 v2 = float3(-0.723, 0.331, 0.0);//float3(2.084, 0.354, 3.858);
    float t, u, v;
    
    
    if(IntersectTriangle(ray, v0, v1, v2, &t, &u, &v))
    {
        if (t > 0 && t < hit.distance)
        {
            hit.distance = t;
            hit.position = ray.origin + ray.direction * t;
            hit.normal = normalize(cross(v1 - v0, v2 - v0));
            hit.albedo = 0.01f;
            hit.specular = 0.65f * float3(1.f, 0.4f, 0.2f);
            hit.refractionColor = float3(0.f, 0.f, 0.f);
            hit.emission = 0.f;
            hit.smoothness = 0.1f;
            hit.inside = false;
        }
    }
    
    
    for (int a = 0; a < 300; a++)
    {
        Triangle tri = triangles[a];
        float3 v0 = tri.v0;
        float3 v1 = tri.v1;
        float3 v2 = tri.v2;
        float t, u, v;
        
        if(IntersectTriangle(ray, v0, v1, v2, &t, &u, &v))
        {
            if (t > 0 && t < hit.distance)
            {
                hit.distance = t;
                hit.position = ray.origin + ray.direction * t;
                hit.normal = normalize(cross(v1 - v0, v2 - v0));
                hit.albedo = 0.01f;
                hit.specular = 0.65f * float3(1.f, 0.4f, 0.2f);
                hit.refractionColor = float3(0.f, 0.f, 0.f);
                hit.emission = 0.f;
                hit.smoothness = 0.1f;
                hit.inside = false;
            }
        }
    }
    */
    
    
    
    
    //IntersectSphere(ray, &hit, s2);
    
    return hit;
}

float3 Shade(thread Ray* ray, RayHit hit)
{
    float3 col = 0.f;
    float _seed = ray->seed;
    float2 jitter = ray->jitter;
    
    if(hit.distance < INFINITY)
    {
        if(hit.inside)
            ray->energy *= exp(hit.refractionColor * hit.distance);    //when negative this is absorb, the inverse of the transmission color
        
        float3 reflected = reflect(ray->direction, hit.normal);
        
        hit.albedo = min(1.f - hit.specular, hit.albedo);
        
        float specularChance = energy(hit.specular);
        float diffuseChance = energy(hit.albedo);
        float refractChance = hit.refractionChance;
        refractChance = energy(hit.refractionColor);
        
        if (specularChance > 0.f)
        {
            specularChance = FresnelReflectAmount(hit.inside? hit.IOR : 1.f, hit.inside? 1.f : hit.IOR, ray->direction, hit.normal, specularChance, 1.f);
            //refractChance *= (1.f - specularChance) / (1.f - energy(hit.specular));
        }
        
        //float roulette = rand(ray->energy);
        //float roulette = rand(&ray->seed, ray->jitter);
        float roulette = rand(_seed, jitter);
        
        _seed += 1.f;
        
        if (specularChance > 0.f && roulette < specularChance)
        {
            float alpha = SmoothnessToAlpha(hit.smoothness);
            float f = (alpha + 2) / (alpha + 1);
            
            //choose a random direction based on the reflected ray, using alpha for BRDF sample
            ray->direction = SampleHemisphere(reflected, alpha, _seed, jitter);
            ray->energy = (1.f / specularChance) * hit.specular * sdot(hit.normal, ray->direction, f);  //use cosine sampling to terminate rays that are unlikely
            ray->origin = hit.position + hit.normal * 0.001f;   //we jiggle this a bit to avoid registering the same hit
        }
        else if(refractChance > 0.f && roulette < specularChance + refractChance)
        {
            float alpha = SmoothnessToAlpha(hit.refractionSmoothness);
            float f = (alpha + 2) / (alpha + 1);
            
            float3 refractedDir = refract(ray->direction, hit.normal, hit.inside? hit.IOR : 1.f / hit.IOR);
            refractedDir = normalize(mix(refractedDir, normalize(-hit.normal + SampleHemisphere(refractedDir, alpha, _seed, jitter)), 0.09f)); //the t (lerp) value affects the magnification of the translucency
            
            ray->direction = refractedDir;
            ray->origin = hit.position - hit.normal * 0.001f;
        }
        else if(diffuseChance > 0.f && roulette < specularChance + diffuseChance)
        {
            ray->direction = SampleHemisphere(hit.normal, 1.f, _seed, jitter);
            ray->energy *= (1.f / diffuseChance) * hit.albedo;
            ray->origin = hit.position + hit.normal * 0.001f;
        }
        else
        {
            ray->energy = 0.f;
            ray->origin = hit.position + hit.normal * 0.001f;
        }
        
        col = hit.emission;
    }
    
    return col;
}

//This needs updating, currently the encoder may attempt to bind unnecessary resources
//the primary Tracer kernel's arguments have changed
kernel void DebugTracer(texture2d<float, access::sample> source [[texture(0)]], texture2d<float, access::read_write> destination [[texture(1)]], constant Triangle *triangles [[buffer(0)]], constant CameraParams *cam [[buffer(1)]], constant Sphere *spheres [[buffer(2)]], constant int& sampleCount [[buffer(3)]], constant float2& jitter [[buffer(4)]], constant BVHNode *BVHTree [[buffer(5)]], uint2 position [[thread_position_in_grid]]) {
    
    //this is a reset frame
    if (sampleCount < 0)
    {
        destination.write(float4(0, 0, 0, 0), position);
        return;
    }
    
    const auto textureSize = ushort2(destination.get_width(), destination.get_height());
    float2 uv = float2( ((float)position.x + jitter.x) / (float)textureSize.x, ((float)position.y + jitter.y) / (float)textureSize.y);
    float4 colInit = destination.read(position).rgba;
    float3 col = float3(0.f, 0.f, 0.f);
    
    uv = uv * 2.f - 1.f;
    Ray ray;
    RayHit hit = CreateRayHit();
    ray.jitter = float2(position.x, position.y);

    float aperture = cam->aperture; //4 pixel wide aperture
    
    ray = CreateCameraRay(uv, cam); //primary ray
    float3 focalPoint = ray.origin + ray.direction * cam->focalLength; // the focal point is 3 units from the aperture
    

        
    hit = Trace(ray, spheres[0], triangles, BVHTree);
    
    if (hit.distance != INFINITY){
        col += float3(1, 1, 1) * (hit.distance);
    }
    else
    {
        float2 sph = CartesianToSpherical(ray.direction);
        col += 0.f;
        col += source.sample(textureSampler, float2(-sph.y, -sph.x)).rgb * ray.energy;
        ray.energy = 0.f;
    }
    
    
    float avgFactor = (1.f / (sampleCount + 1.f));
    auto result = float4( col * avgFactor + (colInit.rgb * (1.f - avgFactor)), 1.f);
    destination.write(result, position);
    
}

kernel void Tracer(texture2d<float, access::sample> source [[texture(0)]], texture2d<float, access::read_write> destination [[texture(1)]], texture2d<int, access::write> albedoNorm [[texture(2)]], texture2d<float, access::write> normal [[texture(3)]], constant CameraParams *cam [[buffer(0)]], constant Sphere *spheres [[buffer(1)]], constant BVHNode *BVHTree [[buffer(2)]], constant int& sampleCount [[buffer(3)]], constant float2& jitter [[buffer(4)]], constant VertexProperties *vertexOptions [[buffer(5)]], constant int& triangleIndices [[buffer(6)]], constant Triangle *triangles [[buffer(7)]], uint2 position [[thread_position_in_grid]]) {
    
    //this is a reset frame
    if (sampleCount < 0)
    {
        destination.write(float4(0, 0, 0, 0), position);
        return;
    }
    
    const auto textureSize = ushort2(destination.get_width(), destination.get_height());
    float2 uv = float2( ((float)position.x + jitter.x) / (float)textureSize.x, ((float)position.y + jitter.y) / (float)textureSize.y);
    float4 colInit = destination.read(position).rgba;
    float3 col = float3(0.f, 0.f, 0.f);
    float3 rayAlbedo = float3();
    float3 rayNormal = float3();
    
    uv = uv * 2.f - 1.f;
    Ray ray;
    RayHit hit = CreateRayHit();
    ray.jitter = float2(position.x, position.y);

    float aperture = cam->aperture; //4 pixel wide aperture
    
    ray = CreateCameraRay(uv, cam); //primary ray
    float3 focalPoint = ray.origin + ray.direction * cam->focalLength; // the focal point is 3 units from the aperture
    
    
    //for the primary ray
    for(int a=0; a<8; a++){
        
        hit = Trace(ray, spheres[0], triangles, BVHTree);
        
        if (hit.distance !=INFINITY){
            if (a == 0)
            {
                rayAlbedo = hit.albedo;
                rayNormal = hit.normal;
            }
            float3 n = ray.energy;
            col += (Shade(&ray, hit) * ray.energy);
            ray.seed += 4.f;
        }
        else
        {
            float2 sph = CartesianToSpherical(ray.direction);
            float3 skyColor = source.sample(textureSampler, float2(-sph.y, -sph.x)).rgb * ray.energy;
            if (a == 0)
            {
                //rayAlbedo = skyColor;
                //rayNormal = hit.normal;
            }
            //col += 0.f;
            col += skyColor;
            ray.energy = 0.f;
            break;
        }
        
        if(!any(ray.energy))
            break;
    }
    float _s = ray.seed;
    float2 _jitter = ray.jitter;
    
    if (sampleCount == 5)
    {
        uint _albedo = Float3toUInt8(rayAlbedo);
        uint _normal = Float3toUInt8(rayNormal);
        int _normalS = NormtoSInt8(rayNormal);
        int _albedoS = ColtoSInt8(rayAlbedo);
        
        albedoNorm.write(int4(_albedo, _normal, 0, 0), position);
        rayNormal = RGB8toRGB32F(_normal);
        rayAlbedo = RGB8toRGB32F(_albedo);
        float3 rayAlbedoS = SInt8toCol(_albedoS);
        normal.write(float4(rayNormal, 1.f), position);
    }
    
    /*
    //the secondary rays (8 of them)
    for (int b=0; b<8; b++)
    {
        float _apertureRadius = rand(_s, _jitter) * aperture;
        _s += 1.f;
        float _randAngle = rand(_s, _jitter) * PI * 2;
        float2 apertureOffset = float2(cos(_randAngle), sin(_randAngle)) * _apertureRadius;
        Ray secondaryRay = CreateSecondaryRay(uv, cam, focalPoint, apertureOffset);
        
     //8 bounces
        for(int c=0; c<8; c++){
            
            hit = Trace(secondaryRay, spheres[0], triangles);
            
            if (hit.distance !=INFINITY){
                col += (Shade(&secondaryRay, hit) * secondaryRay.energy);
                ray.seed += 4.f;
            }
            else
            {
                float2 sph = CartesianToSpherical(secondaryRay.direction);
                col += source.sample(textureSampler, float2(-sph.y, -sph.x)).rgb * secondaryRay.energy;
                secondaryRay.energy = 0.f;
                break;
            }
            
            if(!any(secondaryRay.energy))
                break;
        }
    }
    
    col /= 8.f;
    */
    
    
    float avgFactor = (1.f / (sampleCount + 1.f));
    auto result = float4( col * avgFactor + (colInit.rgb * (1.f - avgFactor)), 1.f);
    destination.write(result, position);
    
}

 

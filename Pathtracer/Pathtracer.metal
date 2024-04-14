//
//  Pathtracer.metal
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

#include <metal_stdlib>
using namespace metal;
#define PI 3.1415926535
#define EPSILON = 1e-8

constant bool deviceSupportsNonuniformThreadgroups [[function_constant(0)]];
constant float2 _Pixel [[function_constant(1)]];
constant float init_Seed [[function_constant(2)]];

constexpr sampler textureSampler(filter::linear, address::repeat);
//device float _Seed;

struct CameraParams {
    float4x4 worldToCamera;
    float4x4 projectionInv;
    float dummy;
};

struct Ray {
    float3 direction;
    float3 origin;
    float3 energy;
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
    bool inside;
};

struct Sphere {
    float4 point;       //position, scale
    float3 albedo;
    float3 specular;
    float3 emission;
    float3 refractionColor;
    float smoothness;
    float refractiveIndex;
    float refractionRoughness;
    float refractionChance;
};

Ray CreateRay(float3 origin, float3 direction){
    Ray ray;
    ray.origin = origin;
    ray.direction = direction;
    ray.energy = float3(1.f, 1.f, 1.f);
    
    return ray;
}

Ray CreateCameraRay(float2 screenPos, constant CameraParams* cam)
{
    Ray ray;
    float3 origin = (float4(0, 0.5f, 0, 1) * cam->worldToCamera).xyz;
    float3 dir = (float4(screenPos, 0, 1) * cam->projectionInv).xyz;
    
    dir = normalize((float4(dir, 0) * cam->worldToCamera).xyz);
    ray = CreateRay(origin, dir);
    
    return ray;
}

RayHit CreateRayHit(){
    RayHit hit;
    hit.distance = INFINITY;
    hit.position = float3(0.f, 0.f, 0.f);
    hit.albedo = float3(0.f, 0.f, 0.f);
    hit.specular = float3(0.f, 0.f, 0.f);
    hit.normal = float3(0.f, 0.f, 0.f);
    hit.refractionColor = float3(0.f, 0.f, 0.f);
    hit.IOR = 1.f;
    hit.refractionChance = 0.f;
    hit.smoothness = 0.f;
    hit.emission = 0.f;
    hit.inside = false;
    return hit;
};


float2 CartesianToSpherical(float3 dir)
{
    float theta = acos(dir.y) / -PI;
    float phi = atan2(dir.x, -dir.z) / -PI * 0.5f;
    return float2(theta, phi);
}

float rand(float _Seed){
    float result = fract(sin(_Seed / 100.f * dot(_Pixel.xy, float2(12.9898f, 78.233f))) * 43758.5453f);
    _Seed += 1.0f;
    return result;
}

void IntersectGroundPlane(Ray ray, thread RayHit* hit)
{
    float t = -ray.origin.y / ray.direction.y;
    
    if(t > 0 && t < hit->distance){
        hit->distance = t;
        hit->position = t * ray.direction + ray.origin;
        hit->normal = float3(0.f, 1.f, 0.f);
        hit->albedo = 0.5f;
        hit->specular = 0.1f;
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
    
    if (dist > 0.f && dist < INFINITY)
    {
        hit->distance = dist;
        hit->position = ray.origin + ray.direction * dist;
        hit->inside = inside;
        hit->normal = normalize(hit->position - sphere.point.xyz) * (inside ? -1.f : 1.f);
        hit->albedo = sphere.albedo;
        hit->emission = sphere.emission;
        hit->smoothness = sphere.smoothness;
        hit->refractionChance = sphere.refractionChance;
        hit->refractionColor = sphere.refractionColor;
        hit->IOR = sphere.refractiveIndex;
    }
    
}

float3 channelSwap(float3 col)
{
    return float3(col.b, col.g, col.r);
}

kernel void Tracer(texture2d<float, access::sample> source [[texture(0)]], texture2d<float, access::write> destination [[texture(1)]], constant float& tint [[buffer(0)]], constant CameraParams *cam [[buffer(1)]], uint2 position [[thread_position_in_grid]]) {
    
    const auto textureSize = ushort2(destination.get_width(), destination.get_height());
    
    /*
    if (!deviceSupportsNonuniformThreadgroups){
        if(position.x >= textureSize.x || position.y >= textureSize.y)
            return;
    }
     */
    
    float2 uv = float2((float)position.x / (float)textureSize.x, (float)position.y / (float)textureSize.y);
    float3 col;
    
    //auto result = source.sample(textureSampler, uv);
    uv = uv * 2.f - 1.f;
    
    //const auto pixVal = source.read(position);
    //const auto result = float4(1.f, 0.f, 0.f, 1.f);       //brg
    Ray ray;
    RayHit hit = CreateRayHit();
    
    Sphere s;
    s.albedo = 0.f;
    s.specular = 0.f;
    s.smoothness = 0.f;
    s.refractionColor = 0.f;
    s.refractiveIndex = 1.f;
    s.refractionChance = 0.f;
    s.point = float4(0, 0.5f, 2.f, 0.8f);

    
    ray = CreateCameraRay(uv, cam);
    IntersectGroundPlane(ray, &hit);
    IntersectSphere(ray, &hit, s);
    
    if (hit.distance == INFINITY){
        float2 sph = CartesianToSpherical(ray.direction);
        col = source.sample(textureSampler, float2(-sph.y, -sph.x)).rgb;
    }
    else {
        col = hit.normal;
    }
    
    auto result = float4(channelSwap(col), 1.0);
    
    //result *= tint;
    //const auto result = float4(abs(uv), 0.f, 1.f) * cam->dummy;
    //auto result = float4(ray.direction.z, ray.direction.g, ray.direction.x, 1.f) * cam->dummy;
    
    destination.write(result, position);
}


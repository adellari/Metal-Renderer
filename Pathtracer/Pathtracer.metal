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
//device float _Seed;

struct Ray {
    float3 direction;
    float3 origin;
    float3 energy;
};

struct RayHit {
    float distance;
    float3 position;
    float3 normal;
    float3 albedo;
};

struct Sphere {
    float4 point;       //position, scale
    float3 albedo;
    float3 specular;
};

Ray CreateRay(float3 origin, float3 direction){
    Ray ray;
    ray.origin = origin;
    ray.direction = direction;
    ray.energy = float3(1.f, 1.f, 1.f);
    
    return ray;
}

RayHit CreateRayHit(){
    RayHit hit;
    hit.distance = INFINITY;
    hit.position = float3(0.f, 0.f, 0.f);
    hit.albedo = float3(0.f, 0.f, 0.f);
    hit.normal = float3(0.f, 0.f, 0.f);
    
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
    }
}

kernel void Tracer(texture2d<float, access::read> source [[texture(0)]], texture2d<float, access::write> destination [[texture(1)]], constant float& tint [[buffer(0)]], uint2 position [[thread_position_in_grid]]) {
    
    const auto textureSize = ushort2(destination.get_width(), destination.get_height());
    
    /*
    if (!deviceSupportsNonuniformThreadgroups){
        if(position.x >= textureSize.x || position.y >= textureSize.y)
            return;
    }
     */
    
    float2 uv = float2((float)position.x / (float)textureSize.x, (float)position.y / (float)textureSize.y);
    uv = uv * 2.f - 1.f;
    
    //const auto pixVal = source.read(position);
    //const auto result = float4(1.f, 0.f, 0.f, 1.f);       //brg
    
    
    const auto result = float4(abs(uv), 0.f, 1.f);
    
    destination.write(result, position);
}


//
//  Pathtracer.metal
//  Pathtracer
//
//  Created by Adellar Irankunda on 3/26/24.
//

#include <metal_stdlib>
using namespace metal;

constant bool deviceSupportsNonuniformThreadgroups [[function_constant(0)]];

kernel void Tracer(texture2d<float, access::read> source [[texture(0)]], texture2d<float, access::write> destination [[texture(1)]], constant float& tint [[buffer(0)]], uint2 position [[thread_position_in_grid]]) {
    
    const auto textureSize = ushort2(destination.get_width(), destination.get_height());
    
    if (!deviceSupportsNonuniformThreadgroups){
        if(position.x >= textureSize.x || position.y >= textureSize.y)
            return;
    }
    
    const auto pixVal = source.read(position);
    const auto result = float4(0.f, 0.5f, 1.f, 1.f);
    destination.write(result, position);
}


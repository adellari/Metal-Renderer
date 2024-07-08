//
//  OIDNHandler.m
//  Pathtracer
//
//  Created by Adellar Irankunda on 5/8/24.
//
#import "OIDNHandler.h"
//#import <Foundation/Foundation.h>
#import "OpenImageDenoise/oidn.h"

@implementation OIDNHandler

OIDNDevice device;
OIDNBuffer colorBuff;
OIDNBuffer albedoBuff;
OIDNBuffer normalBuff;

OIDNFilter filter;
size_t bufferSize;


- (void) InitDevice {
    //printf("hello from objc");
    //NSLog(@"something being called here");
    const char* errorMessage;
    
    device = oidnNewDevice(OIDN_DEVICE_TYPE_DEFAULT);
    
    if (oidnGetDeviceError(device, &errorMessage) != OIDN_ERROR_NONE)
        NSLog(@"Error: %s\n", errorMessage);
    
    oidnCommitDevice(device);
    
    if (oidnGetDeviceError(device, &errorMessage) != OIDN_ERROR_NONE)
        NSLog(@"Error: %s\n", errorMessage);
    
    filter = oidnNewFilter(device, "RT");
    
}

- (void) Release {
    /*
    oidnReleaseBuffer(colorBuf);
    oidnReleaseFilter(filter);
    oidnReleaseDevice(device);
    */
}

- (void) SetBeauty: (const float*)inputBeauty {
    
    bufferSize = 1024 * 512 * 3 * sizeof(float);
    colorBuff = oidnNewBuffer(device, bufferSize);
    
    oidnSetFilterImage(filter, "color", colorBuff, OIDN_FORMAT_FLOAT3, 512, 1024, 0, 0, 0);
    oidnSetFilterImage(filter, "output", colorBuff, OIDN_FORMAT_FLOAT3, 512, 1024, 0, 0, 0);
    oidnSetFilterBool(filter, "hdr", true);
    
    float* colorPtr = (float*)oidnGetBufferData(colorBuff);
    for (int a=0; a<1024 * 512; a++)
    {
        //discard the alpha component by offsetting by 4 in the input array
        colorPtr[a * 3] = inputBeauty[a * 4];
        colorPtr[a * 3 + 1] = inputBeauty[a * 4 + 1];
        colorPtr[a * 3 + 2] = inputBeauty[a * 4 + 2];
    }
    
}

- (void) SetAlbedo: (const float*)inputAlbedo {
    
    albedoBuff = oidnNewBuffer(device, bufferSize);
    
    oidnSetFilterImage(filter, "albedo", colorBuff, OIDN_FORMAT_FLOAT3, 512, 1024, 0, 0, 0);
    
    float* albedoPtr = (float*)oidnGetBufferData(albedoBuff);
    for (int a=0; a<1024 * 512; a++)
    {
        //discard the alpha component by offsetting by 4 in the input array
        albedoPtr[a * 3] = inputAlbedo[a * 4];
        albedoPtr[a * 3 + 1] = inputAlbedo[a * 4 + 1];
        albedoPtr[a * 3 + 2] = inputAlbedo[a * 4 + 2];
    }
    
}

- (void) SetNormal: (const float*)inputNormal {
    
    normalBuff = oidnNewBuffer(device, bufferSize);
    
    oidnSetFilterImage(filter, "normal", normalBuff, OIDN_FORMAT_FLOAT3, 512, 1024, 0, 0, 0);
    
    float* normalPtr = (float*)oidnGetBufferData(normalBuff);
    for (int a=0; a<1024 * 512; a++)
    {
        //discard the alpha component by offsetting by 4 in the input array
        normalPtr[a * 3] = inputNormal[a * 4];
        normalPtr[a * 3 + 1] = inputNormal[a * 4 + 1];
        normalPtr[a * 3 + 2] = inputNormal[a * 4 + 2];
    }
    
}


- (float*) Denoise{
    
    oidnCommitFilter(filter);
    oidnExecuteFilter(filter);
    float* beautyPtr = (float*)oidnGetBufferData(colorBuff);
    
    const char* errorMessage;
    if (oidnGetDeviceError(device, &errorMessage) != OIDN_ERROR_NONE)
        NSLog(@"Error: %s\n", errorMessage);
    else
        NSLog(@"successfully filtered image \n");
    oidnReleaseBuffer(colorBuff);
    oidnReleaseBuffer(normalBuff);
    oidnReleaseBuffer(albedoBuff);
    
    return beautyPtr;
}

@end

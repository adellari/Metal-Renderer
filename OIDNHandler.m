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
OIDNBuffer colorBuf;
OIDNBuffer albedoBuf;
OIDNBuffer normalBuf;

OIDNFilter filter;


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

- (float*) Denoise: (const float*)inputColor {
    
    size_t buffSize = 1024 * 512 * 3 * sizeof(float);
    colorBuf = oidnNewBuffer(device, buffSize);
    
    oidnSetFilterImage(filter, "color", colorBuf, OIDN_FORMAT_FLOAT3, 512, 1024, 0, 0, 0);
    oidnSetFilterImage(filter, "output", colorBuf, OIDN_FORMAT_FLOAT3, 512, 1024, 0, 0, 0);
    
    oidnSetFilterBool(filter, "hdr", true);
    oidnCommitFilter(filter);
    
    float* colorPtr = (float*)oidnGetBufferData(colorBuf);
    
    for (int a=0; a<1024 * 512; a++)
    {
        //discard the a component by offsetting by 4 in the input array
        colorPtr[a * 3] = inputColor[a * 4];
        colorPtr[a * 3 + 1] = inputColor[a * 4 + 1];
        colorPtr[a * 3 + 2] = inputColor[a * 4 + 2];
    }
    //NSLog(@"first bit before: r %e\n", colorPtr[14]);
    oidnExecuteFilter(filter);
    
    const char* errorMessage;
    if (oidnGetDeviceError(device, &errorMessage) != OIDN_ERROR_NONE)
        NSLog(@"Error: %s\n", errorMessage);
    else
        NSLog(@"successfully filtered image \n");
    
    //NSLog(@"first bit after: r %e\n", colorPtr[14]);
    oidnReleaseBuffer(colorBuf);
    
    /*
    NSMutableArray *resultArray = [NSMutableArray array];
    for (int i = 0; i < 1024 * 512 * 3; i++) {
        [resultArray addObject:@(colorPtr[i])];
    }
    */
    //printf("completed execution");
    return colorPtr;
}

@end

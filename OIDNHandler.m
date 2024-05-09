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


- (void) initializeDevice {
    //printf("hello from objc");
    NSLog(@"something being called here");
    const char* errorMessage;
    
    device = oidnNewDevice(OIDN_DEVICE_TYPE_METAL);
    
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

- (void) setImages {
    
    size_t buffSize = 1024 * 1024 * 3 * sizeof(float);
    colorBuf = oidnNewBuffer(device, buffSize);
    
    oidnSetFilterImage(filter, "color", colorBuf, OIDN_FORMAT_FLOAT3, 1024, 1024, 0, 0, 0);
    oidnSetFilterBool(filter, "hdr", true);
    oidnCommitFilter(filter);
    
    float* colorPtr = (float*)oidnGetBufferData(colorBuf);
    oidnExecuteFilter(filter);
    
    const char* errorMessage;
    if (oidnGetDeviceError(device, &errorMessage) != OIDN_ERROR_NONE)
        NSLog(@"Error: %s\n", errorMessage);
    
    //printf("completed execution");
    
}

@end

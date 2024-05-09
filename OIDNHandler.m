//
//  OIDNHandler.m
//  Pathtracer
//
//  Created by Adellar Irankunda on 5/8/24.
//

#import <Foundation/Foundation.h>
#import "OpenImageDenoise/oidn.h"

OIDNDevice device;

void initializeDevice(void)
{
    device = oidnNewDevice(OIDN_DEVICE_TYPE_METAL);
    oidnCommitDevice(device);
}

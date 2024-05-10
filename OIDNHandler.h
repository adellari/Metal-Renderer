//
//  OIDNHandler.h
//  Pathtracer
//
//  Created by Adellar Irankunda on 5/8/24.
//

#import <Foundation/Foundation.h>

@interface OIDNHandler : NSObject

- (void) InitDevice;
- (void) Release;
- (float*) Denoise:(const float*)inputColor;




@end


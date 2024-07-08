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
- (float*) Denoise;
- (void) SetBeauty:(const float*)inputBeauty;
- (void) SetAlbedo:(const float*)inputAlbedo;
- (void) SetNormal:(const float*)inputNormal;



@end


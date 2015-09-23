//
//  LPDLivePhoto.m
//  LivePhotoDemoSwift
//
//  Created by Genady Okrain on 9/23/15.
//  Copyright © 2015 Genady Okrain. All rights reserved.
//

#import "LPDLivePhoto.h"

@implementation LPDLivePhoto

+ (PHLivePhoto *)livePhotoWithImageURL:(NSURL *)imageURL videoURL:(NSURL *)videoURL {
    CGSize targetSize = CGSizeZero;
    PHImageContentMode contentMode = PHImageContentModeDefault;
    PHLivePhoto *livePhoto = [[PHLivePhoto alloc] init];
    SEL initWithImageURLvideoURLtargetSizecontentMode = NSSelectorFromString(@"_initWithImageURL:videoURL:targetSize:contentMode:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[livePhoto methodSignatureForSelector:initWithImageURLvideoURLtargetSizecontentMode]];
    [invocation setSelector:initWithImageURLvideoURLtargetSizecontentMode];
    [invocation setTarget:livePhoto];
    [invocation setArgument:&(imageURL) atIndex:2];
    [invocation setArgument:&(videoURL) atIndex:3];
    [invocation setArgument:&(targetSize) atIndex:4];
    [invocation setArgument:&(contentMode) atIndex:5];
    [invocation invoke];
    return livePhoto;
}

@end

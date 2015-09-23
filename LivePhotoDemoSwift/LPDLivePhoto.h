//
//  LPDLivePhoto.h
//  LivePhotoDemoSwift
//
//  Created by Genady Okrain on 9/23/15.
//  Copyright © 2015 Genady Okrain. All rights reserved.
//

@import Photos;

@interface LPDLivePhoto : NSObject
+ (PHLivePhoto *)livePhotoWithImageURL:(NSURL *)imageURL videoURL:(NSURL *)videoURL;
@end

//
//  OSMKBoundingBox.h
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OSMKBoundingBox : NSObject

@property (nonatomic) double left;
@property (nonatomic) double right;
@property (nonatomic) double top;
@property (nonatomic) double bottom;

+ (instancetype)boundingBoxWithCornersSW:(CLLocationCoordinate2D)southWest NE:(CLLocationCoordinate2D)northEast;

@end

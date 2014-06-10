//
//  OSMKBoundingBox.m
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKBoundingBox.h"

@implementation OSMKBoundingBox

- (NSString *)description
{
    return [NSString stringWithFormat:@"Left: %f\nRight: %f\nTop: %f\nBottom: %f",self.left,self.right,self.top,self.bottom];
}
+ (id)boundingBoxWithCornersSW:(CLLocationCoordinate2D)southWest NE:(CLLocationCoordinate2D)northEast
{
    OSMKBoundingBox * bbox = [[OSMKBoundingBox alloc] init];
    bbox.left = southWest.longitude;
    bbox.bottom = southWest.latitude;
    bbox.right = northEast.longitude;
    bbox.top = northEast.latitude;
    return bbox;
}

@end

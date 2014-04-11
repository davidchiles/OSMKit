//
//  OSMKNode.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKObject.h"
#import <CoreLocation/CoreLocation.h>

@interface OSMKNode : OSMKObject

/** This node latitude. (WGS 84 - SRID 4326) */
@property (nonatomic, readonly)double latitude;
/** This node longitude. (WGS 84 - SRID 4326) */
@property (nonatomic, readonly)double longitude;

@property (nonatomic) CLLocationCoordinate2D coordinate;

@end

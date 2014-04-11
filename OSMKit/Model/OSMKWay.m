//
//  OSMKWay.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKWay.h"

@implementation OSMKWay


- (id)copyWithZone:(NSZone *)zone
{
    OSMKWay *way = [super copyWithZone:zone];
    way.nodes = [self.nodes copyWithZone:zone];
    
    return way;
}

@end

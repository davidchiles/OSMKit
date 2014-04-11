//
//  OSMKRelation.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKRelation.h"

@implementation OSMKRelation

- (id)copyWithZone:(NSZone *)zone
{
    OSMKRelation *relation = [super copyWithZone:zone];
    relation.members = [self.members copyWithZone:zone];
    
    return relation;
}

@end

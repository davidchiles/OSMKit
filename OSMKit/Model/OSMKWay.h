//
//  OSMKWay.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKObject.h"

@interface OSMKWay : OSMKObject

//list of node ids
@property (nonatomic, strong) NSArray *nodes;

@end

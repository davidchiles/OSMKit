//
//  OSMKParseOperation.m
//  OSMKit
//
//  Created by David Chiles on 11/30/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKParseOperation.h"

@interface OSMKParseOperation ()

@end

@implementation OSMKParseOperation

- (instancetype)initWithData:(NSData *)data
{
    if (self = [self init]) {
        _data = data;
    }
    return self;
}

@end

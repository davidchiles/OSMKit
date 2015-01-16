//
//  OSMKTestResult.m
//  OSMKit
//
//  Created by David Chiles on 1/15/15.
//  Copyright (c) 2015 davidchiles. All rights reserved.
//

#import "OSMKTestResult.h"

@implementation OSMKTestResult

- (NSTimeInterval)averageDuration
{
    if (self.iterations > 0) {
        return self.duration / self.iterations;
    }
    return 0;
}

@end

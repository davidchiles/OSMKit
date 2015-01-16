//
//  OSMKTestResult.h
//  OSMKit
//
//  Created by David Chiles on 1/15/15.
//  Copyright (c) 2015 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSMKTestResult : NSObject

@property (nonatomic, strong) NSString *testName;
@property (nonatomic) NSUInteger iterations;
@property (nonatomic) NSTimeInterval duration;

- (NSTimeInterval)averageDuration;

@end

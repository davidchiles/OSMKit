//
//  OSMKParser.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKParser.h"

@interface OSMKParser ()

@property (nonatomic) dispatch_queue_t delegateQueue;
@property (nonatomic, weak) id<OSMKParserDelegateProtocol> delegate;

@end


@implementation OSMKParser

- (instancetype)initWithDelegate:(id<OSMKParserDelegateProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (self = [self init]) {
        self.delegate = delegate;
        if (delegateQueue) {
            self.delegateQueue = delegateQueue;
        }
        else {
            NSString *name = [NSString stringWithFormat:@"%@-delegate",NSStringFromClass([self class])];
            self.delegateQueue = dispatch_queue_create([name UTF8String], 0);
        }
    }
    return self;
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[OSMKParser alloc] initWithDelegate:self.delegate delegateQueue:self.delegateQueue];
}


@end

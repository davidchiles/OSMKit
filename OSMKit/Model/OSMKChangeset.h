//
//  OSMKChangeset.h
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OSMKObject;
@class DDXMLElement;

@interface OSMKChangeset : NSObject

@property (nonatomic, strong, readonly) NSArray *nodes;
@property (nonatomic, strong, readonly) NSArray *ways;
@property (nonatomic, strong, readonly) NSArray *relations;
@property (nonatomic) int64_t changesetID;
@property (nonatomic, strong) NSDictionary *tags;

- (instancetype)initWithTags:(NSDictionary *)tags;

- (void)addElement:(OSMKObject *)element;
- (void)addElements:(NSArray *)elements;

- (DDXMLElement *)PUTXML;

@end

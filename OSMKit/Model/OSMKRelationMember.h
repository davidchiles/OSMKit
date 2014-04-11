//
//  OSMKRelationMember.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSMKObject.h"

@interface OSMKRelationMember : NSObject <NSCopying>

@property (nonatomic) OSMKElementType type;
@property (nonatomic) int64_t ref;
@property (nonatomic, strong) NSString *role;

- (instancetype)initWithAttributesDictionary:(NSDictionary *)dictionary;



@end

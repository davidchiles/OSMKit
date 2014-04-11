//
//  OSMKUser.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSMKUser : NSObject <NSCopying>

@property (nonatomic, readonly) int64_t osmId;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSDate *dateCreated;
@property (nonatomic, strong) NSURL *imageUrl;
@property (nonatomic, strong) NSString *userDescription;
@property (nonatomic) BOOL termsAgreed;
@property (nonatomic) NSInteger changesetCount;
@property (nonatomic) NSInteger traceCount;
@property (nonatomic, strong) NSSet *roles;

@property (nonatomic) NSInteger receivedBlocks;
@property (nonatomic) NSInteger activeReceivedBlocks;
@property (nonatomic) NSInteger issuedBlocks;
@property (nonatomic) NSInteger activeIssuedBlocks;

- (instancetype)initWIthOsmId:(int64_t)osmId;
- (instancetype)initWithAttributesDictionary:(NSDictionary *)attributes;



@end

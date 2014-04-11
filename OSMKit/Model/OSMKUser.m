//
//  OSMKUser.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKUser.h"
#import "OSMKObject.h"

@interface OSMKUser ()

@property (nonatomic) int64_t osmId;

@end

@implementation OSMKUser

- (instancetype)initWIthOsmId:(int64_t)osmId
{
    if (self = [self init]) {
        self.osmId = osmId;
    }
    return self;
}

- (instancetype)initWithAttributesDictionary:(NSDictionary *)attributes
{
    if (self = [self initWIthOsmId:[attributes[@"id"] longLongValue]]) {
        self.displayName = attributes[@"display_name"];
        NSString *timeString = attributes[@"account_created"];
        if ([timeString length]) {
            self.dateCreated = [[OSMKObject defaultDateFormatter] dateFromString:timeString];
        }        
    }
    return self;
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OSMKUser *user = [[[self class] allocWithZone:zone] init];
    user.osmId = self.osmId;
    user.displayName = [self.displayName copyWithZone:zone];
    user.dateCreated = [self.dateCreated copyWithZone:zone];
    user.imageUrl = [self.imageUrl copyWithZone:zone];
    user.userDescription = [self.userDescription copyWithZone:zone];
    user.termsAgreed = self.termsAgreed;
    user.changesetCount = self.changesetCount;
    user.traceCount = self.traceCount;
    user.roles = [self.roles copyWithZone:zone];
    user.receivedBlocks = self.receivedBlocks;
    user.activeReceivedBlocks = self.activeReceivedBlocks;
    user.issuedBlocks = self.issuedBlocks;
    user.activeIssuedBlocks = self.activeIssuedBlocks;
    
    return user;

}

@end

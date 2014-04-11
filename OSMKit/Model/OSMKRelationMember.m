//
//  OSMKRelationMember.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKRelationMember.h"
#import "OSMKObject.h"

@implementation OSMKRelationMember


- (instancetype)initWithAttributesDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        self.ref = [dictionary[@"ref"] longLongValue];
        NSString *typeString = dictionary[@"type"];
        
        self.type = [OSMKObject tyepForString:typeString];
        
        self.role= dictionary[@"role"];
    }
    return self;
}


- (id)copyWithZone:(NSZone *)zone
{
    OSMKRelationMember *member = [[[self class] allocWithZone:zone] init];
    member.ref = self.ref;
    member.type = self.type;
    member.role = [self.role copyWithZone:zone];
    
    return member;
}

@end

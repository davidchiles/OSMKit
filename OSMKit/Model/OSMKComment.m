//
//  OSMKComment.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKComment.h"
#import "OSMKNote.h"

@implementation OSMKComment

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [self init]) {
        NSString *user = dictionary[@"user"];
        if ([user length]) {
            self.user = user;
            self.userId = [dictionary[@"uid"] longLongValue];
        }
        self.text = dictionary[@"text"];
        self.date = [[OSMKNote defaultDateFormatter] dateFromString:dictionary[@"date"]];
        self.action = dictionary[@"action"];
    }
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"user"] = self.user;
    dictionary[@"uid"] = @(self.userId);
    dictionary[@"text"] = self.text;
    dictionary[@"date"] = [[OSMKNote defaultDateFormatter] stringFromDate:self.date];
    
    if ([self.action length]) {
        dictionary[@"action"] = self.action;
    }
    
    return [dictionary copy];
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[OSMKComment alloc] initWithDictionary:[self jsonDictionary]];
}

#pragma - mark Class Methods



+ (instancetype)commentWithDictionary:(NSDictionary *)dictionary
{
    return [[OSMKComment alloc] initWithDictionary:dictionary];
}

@end

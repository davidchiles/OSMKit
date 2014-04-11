//
//  OSMKObject.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKObject.h"

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"

@interface OSMKObject ()

@property (nonatomic) int64_t osmId;

@end

@implementation OSMKObject


- (instancetype)initWithId:(int64_t)osmId
{
    if (self = [super init]) {
        self.osmId = osmId;
    }
    return self;
}

- (instancetype)initWithAttributesDictionary:(NSDictionary *)attributes
{
    if (self = [super init]) {
        self.osmId = [attributes[@"id"] longLongValue];
        self.version = [attributes[@"version"] intValue];
        self.changeset = [attributes[@"changeset"] longLongValue];
        self.userId = [attributes[@"uid"] longLongValue];
        self.visible = [attributes[@"visible"] isEqualToString:@"true"];
        
        self.user = attributes[@"user"];
        self.action = attributes[@"action"];
        
        NSString *timeString = attributes[@"timestamp"];
        if ([timeString length]) {
            self.timeStamp = [[OSMKObject defaultDateFormatter] dateFromString:timeString];
        }
        
    }
    return self;
}

#pragma NSCopying Methods

- (id)copyWithZone:(NSZone *)zone
{
    OSMKObject *object = [[[self class] allocWithZone:zone] initWithId:self.osmId];
    object.version = self.version;
    object.changeset = self.changeset;
    object.userId = self.userId;
    object.visible = self.visible;
    object.tags = [self.tags copyWithZone:zone];
    object.user = [self.user copyWithZone:zone];
    object.action = [self.action copyWithZone:zone];
    object.timeStamp = [self.timeStamp copyWithZone:zone];
    
    return object;
}

#pragma - mark Class Methods

+ (NSDateFormatter *)defaultDateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ssZ"];
    });
    
    return dateFormatter;
}

+ (NSString *)stringForType:(OSMKElementType)type
{
    NSString *string = nil;
    if (type == OSMKElementTypeNode) {
        string = @"node";
    }
    else if (type == OSMKElementTypeWay) {
        string = @"way";
    }
    else if (type == OSMKElementTypeRelation) {
        string = @"relation";
    }
    
    return string;
}

+ (OSMKElementType)tyepForString:(NSString *)string
{
    OSMKElementType type = OSMKElementTypeNone;
    if ([string isEqualToString:@"node"]) {
        type = OSMKElementTypeNode;
    }
    else if ([string isEqualToString:@"way"]) {
        type = OSMKElementTypeWay;
    }
    else if ([string isEqualToString:@"relation"]) {
        type = OSMKElementTypeRelation;
    }
    
    return type;
}

+ (id)objectForType:(OSMKElementType)type elementId:(int64_t)elementId
{
    id element = nil;
    switch (type) {
        case OSMKElementTypeNode:
            element = [[OSMKNode alloc] initWithId:elementId];
            break;
        case OSMKElementTypeWay:
            element = [[OSMKWay alloc] initWithId:elementId];
            break;
        case OSMKElementTypeRelation:
            element = [[OSMKRelation alloc] initWithId:elementId];
            break;
        default:
            break;
    }
    return element;
}

@end

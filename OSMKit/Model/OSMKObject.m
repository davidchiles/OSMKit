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

#import "DDXMLElement.h"
#import "DDXMLElementAdditions.h"

@interface OSMKObject ()

@property (nonatomic, strong) NSDate *timeStamp;

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
        
        self.timeStampString = attributes[@"timestamp"];
    }
    return self;
}

- (void)setTimeStampString:(NSString *)timeStampString
{
    _timeStampString = timeStampString;
    _timeStamp = nil;
}

- (NSDate *)timeStamp
{
    if (_timeStamp) {
        return _timeStamp;
    }
    
    if ([self.timeStampString length]) {
        _timeStamp = [[OSMKObject defaultDateFormatter] dateFromString:self.timeStampString];
    }
    else {
        _timeStamp = nil;
    }
    
    return _timeStamp;
}

#pragma - mark XML

- (NSString *)xmlName
{
    if ([self isKindOfClass:[OSMKNode class]]) {
        return @"node";
    }
    else if ([self isKindOfClass:[OSMKWay class]]) {
        return @"way";
    }
    else if ([self isKindOfClass:[OSMKRelation class]]) {
        return @"relation";
    }
    return nil;
}

- (DDXMLElement *)DELETEEelementForChangeset:(NSNumber *)changeset
{
    DDXMLElement *objectXML = [[DDXMLElement alloc] initWithName:[self xmlName]];
    if (self.osmId > 0) {
        [objectXML addAttributeWithName:@"id" stringValue:[@(self.osmId) stringValue]];
        [objectXML addAttributeWithName:@"version" stringValue:[@(self.version) stringValue]];
    }
    [objectXML addAttributeWithName:@"changeset" stringValue:[changeset stringValue]];
    return objectXML;
}

- (DDXMLElement *)PUTElementForChangeset:(NSNumber *)changeset
{
    DDXMLElement *objectXML = [self PUTElementForChangeset:changeset];
    [objectXML setAttributes:[OSMKObject tagXML:self.tags]];
    return objectXML;
}

+ (NSArray *)tagXML:(NSDictionary *)tags
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[tags.allKeys count]];
    [tags enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        DDXMLElement *tagElement = [DDXMLElement elementWithName:@"tag"];
        DDXMLNode *keyNode = [DDXMLNode attributeWithName:@"k" stringValue:key];
        DDXMLNode *valueNode = [DDXMLNode attributeWithName:@"v" stringValue:value];
        [tagElement setAttributes:@[keyNode,valueNode]];
        [array addObject:tagElement];
    }];
    return [array copy];
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
    object.action = self.action;
    object.timeStampString = [self.timeStampString copyWithZone:zone];
    
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

+ (OSMKElementType)typeForString:(NSString *)string
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

+ (instancetype)objectForType:(OSMKElementType)type elementId:(int64_t)elementId
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

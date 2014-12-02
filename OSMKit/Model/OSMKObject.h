//
//  OSMKObject.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DDXMLElement;

typedef NS_ENUM(int, OSMKElementType) {
    OSMKElementTypeNone          = 0,
    OSMKElementTypeNode          = 1,
    OSMKElementTypeWay           = 2,
    OSMKElementTypeRelation      = 3
};

typedef NS_ENUM(NSInteger, OSMKElementAction) {
    OSMKElementActionNone = 0,
    OSMKElementActionNew = 1,
    OSMKElementActionModified = 2,
    OSMKElementActionDelete = 3
};

@interface OSMKObject : NSObject <NSCopying>

@property (nonatomic) int64_t osmId;
@property (nonatomic) int version;
@property (nonatomic) int64_t changeset;
@property (nonatomic) int64_t userId;
@property (nonatomic, getter = isVisible) BOOL visible;
@property (nonatomic) OSMKElementAction action;

@property (nonatomic, strong) NSDictionary *tags;
@property (nonatomic, strong) NSString *user;

//Use NSString to set and will be parsed upon getting from the timeStamp and stored
//Improves parsing time significantly because the cost of NSDateFormatter
@property (nonatomic, strong) NSString *timeStampString;
@property (nonatomic, strong, readonly) NSDate *timeStamp;

- (instancetype)initWithId:(int64_t)osmId;
- (instancetype)initWithAttributesDictionary:(NSDictionary *)attributes;

- (DDXMLElement *)PUTElementForChangeset:(NSNumber *)changeset;
- (DDXMLElement *)DELETEEelementForChangeset:(NSNumber *)changeset;

+ (NSArray *)tagXML:(NSDictionary *)tags;

+ (NSDateFormatter *)defaultDateFormatter;

+ (instancetype)objectForType:(OSMKElementType)type elementId:(int64_t)elementId;

+ (NSString *)stringForType:(OSMKElementType)type;
+ (OSMKElementType)typeForString:(NSString *)string;

@end

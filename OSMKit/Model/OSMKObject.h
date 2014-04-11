//
//  OSMKObject.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, OSMKElementType) {
    OSMKElementTypeNone          = 0,
    OSMKElementTypeNode          = 1,
    OSMKElementTypeWay           = 2,
    OSMKElementTypeRelation      = 3
};

@interface OSMKObject : NSObject <NSCopying>

@property (nonatomic, readonly) int64_t osmId;
@property (nonatomic) int version;
@property (nonatomic) int64_t changeset;
@property (nonatomic) int64_t userId;
@property (nonatomic, getter = isVisible) BOOL visible;

@property (nonatomic, strong) NSDictionary *tags;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSDate *timeStamp;

- (instancetype)initWithId:(int64_t)osmId;
- (instancetype)initWithAttributesDictionary:(NSDictionary *)attributes;

+ (NSDateFormatter *)defaultDateFormatter;

+ (id)objectForType:(OSMKElementType)type elementId:(int64_t)elementId;

+ (NSString *)stringForType:(OSMKElementType)type;
+ (OSMKElementType)tyepForString:(NSString *)string;

@end

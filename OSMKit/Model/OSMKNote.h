//
//  OSMKNote.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>

@interface OSMKNote : NSObject <NSCopying>

/** This node latitude. (WGS 84 - SRID 4326) */
@property (nonatomic, readonly)double latitude;
/** This node longitude. (WGS 84 - SRID 4326) */
@property (nonatomic, readonly)double longitude;

@property (nonatomic) int64_t osmId;
@property (nonatomic) BOOL isOpen;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic,strong) NSArray *commentsArray;
@property (nonatomic,strong) NSDate *dateCreated;
@property (nonatomic,strong) NSDate *dateClosed;

- (id)initWithJSONDictionary:(NSDictionary *)noteDictionary;

+ (instancetype)noteWithJSONDictionary:(NSDictionary *)jsonDictionary;

+ (NSDateFormatter *)defaultDateFormatter;

@end

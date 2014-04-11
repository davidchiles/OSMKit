//
//  OSMKNote.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKNote.h"
#import "OSMKObject.h"
#import "OSMKComment.h"

@implementation OSMKNote


- (id)initWithJSONDictionary:(NSDictionary *)noteDictionary
{
    if (self = [self init]) {
        if ([noteDictionary count]) {
            
            NSDictionary * propertiesDictionary = noteDictionary[@"properties"];
            self.osmId = [propertiesDictionary[@"id"] longLongValue];
            NSArray *coordinatesArray = noteDictionary[@"geometry"][@"coordinates"];
            if ([coordinatesArray count] == 2) {
                self.coordinate = CLLocationCoordinate2DMake([coordinatesArray[1] doubleValue], [coordinatesArray[0] doubleValue]);
            }
            
            NSString * statusString = (NSString *)propertiesDictionary[@"status"];
            self.isOpen = [statusString isEqualToString:@"open"];
            self.dateCreated = [[OSMKNote defaultDateFormatter] dateFromString:propertiesDictionary[@"date_created"]];
            self.dateClosed = [[OSMKNote defaultDateFormatter] dateFromString:propertiesDictionary[@"closed_at"]];
            
            __block NSMutableArray * newComments = [NSMutableArray array];
            NSArray * comments = (NSArray *)propertiesDictionary[@"comments"];
            [comments enumerateObjectsUsingBlock:^(NSDictionary *dictionary, NSUInteger idx, BOOL *stop) {
                OSMKComment *comment = [[OSMKComment alloc] initWithDictionary:dictionary];
                
                [newComments addObject:comment];
            }];
            self.commentsArray = newComments;
        }
    }
    return self;
}

- (double)latitude
{
    return self.coordinate.latitude;
}

- (double)longitude
{
    return self.coordinate.longitude;
}

#pragma - mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OSMKNote *note = [[OSMKNote allocWithZone:zone] init];
    note.coordinate = self.coordinate;
    note.osmId = self.osmId;
    note.isOpen = self.isOpen;
    note.dateCreated = [self.dateCreated copyWithZone:zone];
    note.dateClosed = [self.dateClosed copyWithZone:zone];
    note.commentsArray = [self.commentsArray copyWithZone:zone];
    
    return note;
}

#pragma - mark Class Methods

+ (instancetype)noteWithJSONDictionary:(NSDictionary *)noteDictionary
{
    return [[OSMKNote alloc] initWithJSONDictionary:noteDictionary];
}

+ (NSDateFormatter *)defaultDateFormatter
{
    static NSDateFormatter *dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];
    });
    
    return dateFormatter;
}

@end

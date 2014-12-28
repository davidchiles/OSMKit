//
//  OSMKNSJSONSerializationParser.m
//  OSMKit
//
//  Created by David Chiles on 4/21/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKNSJSONSerialization.h"
#import "OSMKNote.h"

@interface OSMKNSJSONSerialization ()

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSInputStream *inputStream;

@property (nonatomic, strong) NSDictionary *serializedDictionary;

@end

@implementation OSMKNSJSONSerialization
- (instancetype)initWithData:(NSData *)data
{
    if (self = [self init]) {
        self.data = data;
    }
    return self;
}

- (id)initWithStream:(NSInputStream *)inputStream {
    if (self =  [self init]) {
        self.inputStream = inputStream;
    }
    return self;
}

- (NSDictionary *)serializedDictionary
{
    if (!_serializedDictionary) {
        if (self.inputStream) {
            _serializedDictionary = [NSJSONSerialization JSONObjectWithStream:self.inputStream options:0 error:nil];
        }
        else {
            _serializedDictionary = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:nil];
        }
    }
    return _serializedDictionary;
}

- (NSArray *)parseNotes
{
    NSMutableArray *foundNotes = [NSMutableArray new];
    if ([self.serializedDictionary[@"type"] isEqualToString:@"FeatureCollection"]) {
        NSArray * notes = self.serializedDictionary[@"features"];
        [notes enumerateObjectsUsingBlock:^(NSDictionary *noteDictionary, NSUInteger idx, BOOL *stop) {
            
            OSMKNote *note = [OSMKNote noteWithJSONDictionary:noteDictionary];
            [foundNotes addObject:note];
        }];
    }
    else if ([self.serializedDictionary[@"type"] isEqualToString:@"Feature"])
    {
        OSMKNote *note = [OSMKNote noteWithJSONDictionary:self.serializedDictionary];
        [foundNotes addObject:note];
    }
    
    if (![foundNotes count]) {
        foundNotes = nil;
    }
    return foundNotes;
}

@end

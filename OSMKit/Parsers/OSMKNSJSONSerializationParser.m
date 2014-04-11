//
//  OSMKNSJSONSerializationParser.m
//  OSMKit
//
//  Created by David Chiles on 4/21/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKNSJSONSerializationParser.h"
#import "OSMKNote.h"

@interface OSMKNSJSONSerializationParser ()

@property (nonatomic) dispatch_queue_t parseQueue;

@end

@implementation OSMKNSJSONSerializationParser

- (id)init {
    if (self = [super init]) {
        NSString *queueString = [NSString stringWithFormat:@"%@-parse",NSStringFromClass([self class])];
        self.parseQueue = dispatch_queue_create([queueString UTF8String], 0);
    }
    return self;
}


- (void)parseJSONData:(NSData *)data
{
    
    dispatch_async(self.parseQueue, ^{
        [self didStart];
        NSError *error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        if (error) {
            [self didFindError:error];
        }
        else {
            [self findNotes:dictionary];
        }
        
        
        
        [self didFinish];
    });
    
}

- (void)parseJSONStream:(NSInputStream *)stream
{
    dispatch_async(self.parseQueue, ^{
        [self didStart];
        NSError *error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithStream:stream options:0 error:&error];
        
        if (error) {
            [self didFindError:error];
        }
        else {
            [self findNotes:dictionary];
        }
        
        [self didFinish];
    });
    
}

- (void)parseJSONDictionary:(NSDictionary *)dictionary
{
    dispatch_async(self.parseQueue, ^{
        [self didStart];
        
        [self findNotes:dictionary];
        
        [self didFinish];
    });
}

- (void)findNotes:(NSDictionary *)dictionary
{
    if ([dictionary[@"type"] isEqualToString:@"FeatureCollection"]) {
        NSArray * notes = [dictionary objectForKey:@"features"];
        [notes enumerateObjectsUsingBlock:^(NSDictionary *noteDictionary, NSUInteger idx, BOOL *stop) {
            
            OSMKNote *note = [OSMKNote noteWithJSONDictionary:noteDictionary];
            [self foundNote:note];
        }];
    }
    else if ([dictionary[@"type"] isEqualToString:@"Feature"])
    {
        OSMKNote *note = [OSMKNote noteWithJSONDictionary:dictionary];
        [self foundNote:note];
    }
}

- (void)didStart
{
    if ([self.delegate respondsToSelector:@selector(parserDidStart:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate parserDidStart:self];
        });
    }
}

- (void)didFinish
{
    if ([self.delegate respondsToSelector:@selector(parserDidFinish:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate parserDidFinish:self];
        });
    }
}

- (void)didFindError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(parser:parseErrorOccurred:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate parser:self parseErrorOccurred:error];
        });
    }
}

- (void)foundNote:(OSMKNote *)note
{
    if (note && [self.delegate respondsToSelector:@selector(parser:didFindNote:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate parser:self didFindNote:[note copy]];
        });
    
    }
}


@end

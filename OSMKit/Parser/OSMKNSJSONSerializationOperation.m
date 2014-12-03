//
//  OSMKNSJSONSerializationParser.m
//  OSMKit
//
//  Created by David Chiles on 4/21/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKNSJSONSerializationOperation.h"
#import "OSMKNote.h"

@interface OSMKNSJSONSerializationOperation ()

@property (nonatomic, strong) NSInputStream *inputStream;

@end

@implementation OSMKNSJSONSerializationOperation

- (id)initWithStream:(NSInputStream *)inputStream {
    if (self =  [self init]) {
        self.inputStream = inputStream;
    }
    return self;
}

- (void)main
{
    NSDictionary *dictionary = nil;
    NSError *error = nil;
    NSArray *notes;
    if (self.inputStream) {
        dictionary = [NSJSONSerialization JSONObjectWithStream:self.inputStream options:0 error:&error];
    }
    else {
        dictionary = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
    }
    
    if (error) {
        [self didFindError:error];
    }
    else {
        notes = [self findNotes:dictionary];
    }
    
    dispatch_queue_t queue = self.completionQueue ?: dispatch_get_main_queue();
    
    if (self.notesCompletionBlock) {
        dispatch_async(queue, ^{
            self.notesCompletionBlock(notes);
        });
    }
    
    if (self.elementsCompletionBlock) {
        dispatch_async(queue, ^{
            self.elementsCompletionBlock(nil,nil,nil);
        });
    }
    
    if (self.usersCompletionBlock) {
        dispatch_async(queue, ^{
            self.usersCompletionBlock(nil);
        });
    }

    
}

- (NSArray *)findNotes:(NSDictionary *)dictionary
{
    __block NSMutableArray *foundNotes = [NSMutableArray new];
    if ([dictionary[@"type"] isEqualToString:@"FeatureCollection"]) {
        NSArray * notes = [dictionary objectForKey:@"features"];
        [notes enumerateObjectsUsingBlock:^(NSDictionary *noteDictionary, NSUInteger idx, BOOL *stop) {
            
            OSMKNote *note = [OSMKNote noteWithJSONDictionary:noteDictionary];
            [foundNotes addObject:note];
        }];
    }
    else if ([dictionary[@"type"] isEqualToString:@"Feature"])
    {
        OSMKNote *note = [OSMKNote noteWithJSONDictionary:dictionary];
        [foundNotes addObject:note];
    }
    
    if (![foundNotes count]) {
        foundNotes = nil;
    }
    return foundNotes;
}

- (void)didFindError:(NSError *)error
{

}

@end

//
//  OSMKParser.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKParser.h"


@implementation OSMKParser


+ (void)parseElementsData:(NSData *)data
           withCompletion:(OSMKElementsCompletionBlock *)completion
{
    [self parseElementsData:data withCompletion:completion completionQueue:nil];
}

+ (void)parseElementsData:(NSData *)data
           withCompletion:(OSMKElementsCompletionBlock *)completion
          completionQueue:(dispatch_queue_t)competionQueue
{
    
}

+ (void)parseNotesData:(NSData *)data
        withCompletion:(OSMKNotesCompletionBlock *)completion
{
    [self parseNotesData:data withCompletion:completion completionQueue:nil];
}

+ (void)parseNotesData:(NSData *)data
        withCompletion:(OSMKNotesCompletionBlock *)completion
       completionQueue:(dispatch_queue_t)completionQueue
{
    
}

+ (void)parseUsersData:(NSData *)data
        withCompletion:(OSMKUsersCompletionBlock *)completion
{
    [self parseUsersData:data withCompletion:completion completionQueue:nil];
}

+ (void)parseUsersData:(NSData *)data
        withCompletion:(OSMKUsersCompletionBlock *)completion
       completionQueue:(dispatch_queue_t)competionQueue
{
    
}


@end

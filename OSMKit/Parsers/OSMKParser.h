//
//  OSMKParser.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OSMKElementsCompletionBlock)(NSArray *nodes, NSArray *ways, NSArray *relations, NSError *error);
typedef void (^OSMKNotesCompletionBlock)(NSArray *notes, NSError *error);
typedef void (^OSMKUsersCompletionBlock)(NSArray *users, NSError *error);

@interface OSMKParser : NSObject

+ (void)parseElementsData:(NSData *)data
           withCompletion:(OSMKElementsCompletionBlock *)completion;

+ (void)parseElementsData:(NSData *)data
           withCompletion:(OSMKElementsCompletionBlock *)completion
          completionQueue:(dispatch_queue_t)competionQueue;

+ (void)parseNotesData:(NSData *)data
        withCompletion:(OSMKNotesCompletionBlock *)completion;

+ (void)parseNotesData:(NSData *)data
        withCompletion:(OSMKNotesCompletionBlock *)completion
       completionQueue:(dispatch_queue_t)completionQueue;

+ (void)parseUsersData:(NSData *)data
        withCompletion:(OSMKUsersCompletionBlock *)completion;

+ (void)parseUsersData:(NSData *)data
        withCompletion:(OSMKUsersCompletionBlock *)completion
       completionQueue:(dispatch_queue_t)competionQueue;


@end

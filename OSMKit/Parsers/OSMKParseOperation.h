//
//  OSMKParseOperation.h
//  OSMKit
//
//  Created by David Chiles on 11/30/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OSMKElementsCompletionBlock)(NSArray *nodes, NSArray *ways, NSArray *relations, NSError *error);
typedef void (^OSMKNotesCompletionBlock)(NSArray *notes, NSError *error);
typedef void (^OSMKUsersCompletionBlock)(NSArray *users, NSError *error);

@interface OSMKParseOperation : NSOperation

@property (nonatomic, strong, readonly) NSData *data;

@property (nonatomic, copy) OSMKElementsCompletionBlock elementsCompletionBlock;
@property (nonatomic, copy) OSMKNotesCompletionBlock notesCompletionBlock;
@property (nonatomic, copy) OSMKUsersCompletionBlock usersCompletionBlock;

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

- (instancetype)initWithData:(NSData *)data;

@end

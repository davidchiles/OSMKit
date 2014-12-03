//
//  OSMKSpatiaLiteStorageOperation.h
//  OSMKit
//
//  Created by David Chiles on 12/2/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSMKit.h"

@class FMDatabaseQueue;

@interface OSMKSpatiaLiteStorageSaveOperation : NSOperation

@property (nonatomic, copy) OSMKElementsCompletionBlock elementsCompletionBlock;
@property (nonatomic, copy) OSMKNotesCompletionBlock notesCompletionBlock;
@property (nonatomic, copy) OSMKUsersCompletionBlock usersCompletionBlock;
@property (nonatomic, copy) OSMKErrorBlock errorBlock;

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databseQueue
                                nodes:(NSArray *)nodes
                                 ways:(NSArray *)ways
                            relations:(NSArray *)relations;

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databseQueue
                                notes:(NSArray *)notes;

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databseQueue
                                users:(NSArray *)users;

@end

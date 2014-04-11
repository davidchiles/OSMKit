//
//  OSMKStorage.h
//  OSMKit
//
//  Created by David Chiles on 4/11/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSMKXMLParser.h"

@class OSMKStorage;
@class OSMKNSJSONSerializationParser;

@protocol OSMKStorageDelegateProtocol <NSObject>

- (void)storageDidStartImporting:(OSMKStorage *)storage;
- (void)storage:(OSMKStorage *)storage didSaveNodes:(NSArray *)nodes;
- (void)storage:(OSMKStorage *)storage didSaveWays:(NSArray *)ways;
- (void)storage:(OSMKStorage *)storage didSaveRelations:(NSArray *)relations;
- (void)storage:(OSMKStorage *)storage didSaveUsers:(NSArray *)users;
- (void)storage:(OSMKStorage *)storage didSaveNotes:(NSArray *)notes;
- (void)storageDidFinishImporting:(OSMKStorage *)storage;

@end

@interface OSMKStorage : NSObject <OSMKParserDelegateProtocol>

@property (nonatomic, weak) id <OSMKStorageDelegateProtocol> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t delegateQueue;
@property (nonatomic, strong, readonly) dispatch_queue_t storageQueue;
@property (nonatomic, strong, readonly) dispatch_queue_t parserDelegateQueue;
@property (nonatomic, strong, readonly) OSMKXMLParser *xmlParser;
@property (nonatomic, strong, readonly) OSMKNSJSONSerializationParser *jsonParser;
@property (nonatomic, strong, readonly) NSString *filePath;


- (instancetype)initWithdatabaseFilePath:(NSString *)filePath
                                delegate:(id<OSMKStorageDelegateProtocol>)delegate
                           delegateQueue:(dispatch_queue_t)delegateQueue;

- (instancetype)initWithdatabaseFilePath:(NSString *)filePath
                                delegate:(id<OSMKStorageDelegateProtocol>)delegate
                           delegateQueue:(dispatch_queue_t)delegateQueue
                               overwrite:(BOOL)overwrite;

- (void)importXMLData:(NSData *)data;
- (void)importJSONData:(NSData *)data;


@end

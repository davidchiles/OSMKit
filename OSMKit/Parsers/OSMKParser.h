//
//  OSMKParser.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OSMKNode;
@class OSMKWay;
@class OSMKRelation;
@class OSMKNote;
@class OSMKUser;
@class OSMKParser;

@protocol OSMKParserDelegateProtocol <NSObject>

- (void)parserDidStart:(OSMKParser *)parser;
- (void)parser:(OSMKParser *)parser didFindNode:(OSMKNode *)node;
- (void)parser:(OSMKParser *)parser didFindWay:(OSMKWay *)way;
- (void)parser:(OSMKParser *)parser didFindRelation:(OSMKRelation *)relation;
- (void)parser:(OSMKParser *)parser didFindNote:(OSMKNote *)note;
- (void)parser:(OSMKParser *)parser didFindUser:(OSMKUser *)user;
- (void)parserDidFinish:(OSMKParser *)parser;
- (void)parser:(OSMKParser *)parser parseErrorOccurred:(NSError *)parseError;



@end

@interface OSMKParser : NSObject <NSCopying>

@property (nonatomic, weak, readonly) id<OSMKParserDelegateProtocol> delegate;
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;

- (instancetype)initWithDelegate:(id<OSMKParserDelegateProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

@end

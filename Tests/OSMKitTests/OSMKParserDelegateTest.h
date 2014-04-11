//
//  OSMKParserDelegateTest.h
//  OSMKit
//
//  Created by David Chiles on 4/11/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OSMKParser.h"

typedef void (^OSMKParseCompletionBlock)(void);

@interface OSMKParserDelegateTest : NSObject <OSMKParserDelegateProtocol>

@property (nonatomic) int waysCount;
@property (nonatomic) int nodesCount;
@property (nonatomic) int relationsCount;
@property (nonatomic) int usersCount;
@property (nonatomic) int notesCount;

@property (nonatomic, strong) OSMKParseCompletionBlock completionBlock;

@end

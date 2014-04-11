//
//  OSMKParserDelegateTest.m
//  OSMKit
//
//  Created by David Chiles on 4/11/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKParserDelegateTest.h"

@implementation OSMKParserDelegateTest

- (id)init
{
    if (self = [super init]) {
        self.nodesCount = 0;
        self.waysCount = 0;
        self.relationsCount = 0;
        self.usersCount = 0;
        self.notesCount = 0;
    }
    return self;
}


#pragma - mark OSMKParserProtocolDelegate Methods

- (void)parserDidStart:(OSMKParser *)parser
{
//    self.nodesCount = 0;
//    self.waysCount = 0;
//    self.relationsCount = 0;
//    self.usersCount = 0;
//    self.notesCount = 0;
}
- (void)parser:(OSMKParser *)parser didFindNode:(OSMKNode *)node
{
    self.nodesCount += 1;
}
- (void)parser:(OSMKParser *)parser didFindWay:(OSMKWay *)way
{
    self.waysCount += 1;
}
- (void)parser:(OSMKParser *)parser didFindRelation:(OSMKRelation *)relation
{
    self.relationsCount += 1;
}
- (void)parser:(OSMKParser *)parser didFindNote:(OSMKNote *)note
{
    self.notesCount += 1;
}
- (void)parser:(OSMKParser *)parser didFindUser:(OSMKUser *)user
{
    self.usersCount += 1;
}
- (void)parserDidFinish:(OSMKParser *)parser
{
    if (self.completionBlock) {
        self.completionBlock();
    }
}


@end

//
//  OSMKChangeset.m
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKChangeset.h"

#import "OSMKObject.h"
#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "DDXML.h"

@implementation OSMKChangeset

- (instancetype)initWithTags:(NSDictionary *)tags
{
    if (self = [self init]) {
        self.tags = tags;
    }
    return self;
}

- (NSArray *)nodes
{
    if (!_nodes) {
        _nodes = [NSArray array];
    }
    return _nodes;
}

- (NSArray *)ways
{
    if (!_ways) {
        _ways = [NSArray array];
    }
    return _ways;
}

- (NSArray *)relations
{
    if (!_relations) {
        _relations = [NSArray array];
    }
    return _relations;
}

- (void)addElement:(OSMKObject *)element
{
    if (!element) {
        return;
    }
    
    if ([element isKindOfClass:[OSMKNode class]]) {
        self.nodes = [self.nodes arrayByAddingObject:element];
    }
    else if ([element isKindOfClass:[OSMKWay class]]) {
        self.ways = [self.ways arrayByAddingObject:element];
    }
    else if ([element isKindOfClass:[OSMKRelation class]]) {
        self.relations = [self.relations arrayByAddingObject:element];
    }
}

- (DDXMLElement *)PUTXML {
    DDXMLElement *element = [[DDXMLElement alloc] initWithName:@"changeset"];
    [element setChildren:[OSMKObject tagXML:self.tags]];
    return element;
}

@end

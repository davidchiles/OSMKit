//
//  OSMKWay.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKWay.h"
#import "DDXMLElement.h"
#import "DDXMLElementAdditions.h"

@implementation OSMKWay


- (DDXMLElement *)DELETEEelentForChangeset:(NSNumber *)changeset
{
    DDXMLElement *element = [super DELETEEelentForChangeset:changeset];
    return [self addNodes:element];
}

- (DDXMLElement *)PUTElementForChangeset:(NSNumber *)changeset
{
    DDXMLElement *element = [super PUTElementForChangeset:changeset];
    return [self addNodes:element];
}

- (DDXMLElement *)addNodes:(DDXMLElement *)element;
{
    for (NSNumber *nodeID in self.nodes) {
        DDXMLElement *nd = [DDXMLElement elementWithName:@"nd"];
        [nd addAttributeWithName:@"ref" stringValue:[nodeID stringValue]];
        [element addChild:nd];
    }
    return element;
}

- (id)copyWithZone:(NSZone *)zone
{
    OSMKWay *way = [super copyWithZone:zone];
    way.nodes = [self.nodes copyWithZone:zone];
    
    return way;
}

@end

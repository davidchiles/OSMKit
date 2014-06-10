//
//  OSMKRelation.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "DDXMLElement.h"
#import "DDXMLElementAdditions.h"

@implementation OSMKRelation

- (DDXMLElement *)DELETEEelentForChangeset:(NSNumber *)changeset
{
    DDXMLElement *element = [super DELETEEelentForChangeset:changeset];
    return [self addMembers:element];
}

- (DDXMLElement *)PUTElementForChangeset:(NSNumber *)changeset
{
    DDXMLElement *element = [super PUTElementForChangeset:changeset];
    return [self addMembers:element];
}

- (DDXMLElement *)addMembers:(DDXMLElement *)element
{
    for (OSMKRelationMember *member in self.members) {
        DDXMLElement *element = [DDXMLElement elementWithName:@"member"];
        
        if ([member.role length]) {
            [element addAttributeWithName:@"role" stringValue:member.role];
        }
        [element addAttributeWithName:@"type" stringValue:[OSMKObject stringForType:member.type]];
        [element addAttributeWithName:@"ref" stringValue:[@(member.ref) stringValue]];
    }
    return element;
}

- (id)copyWithZone:(NSZone *)zone
{
    OSMKRelation *relation = [super copyWithZone:zone];
    relation.members = [self.members copyWithZone:zone];
    
    return relation;
}

@end

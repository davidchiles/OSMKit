//
//  OSMKNode.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKNode.h"

#import "DDXMLElement.h"
#import "DDXMLElementAdditions.h"

@implementation OSMKNode

- (instancetype)initWithAttributesDictionary:(NSDictionary *)attributes
{
    if (self = [super initWithAttributesDictionary:attributes]) {
        double lat = [attributes[@"lat"] doubleValue];
        double lon = [attributes[@"lon"] doubleValue];
        self.coordinate = CLLocationCoordinate2DMake(lat, lon);
        
    }
    return self;
}

-(NSString*) description {
	return [NSString stringWithFormat:@"Node(%lli)%f,%f", self.osmId, self.latitude, self.longitude];
}

- (double)latitude
{
    return self.coordinate.latitude;
}

- (double)longitude
{
    return self.coordinate.longitude;
}

- (DDXMLElement *)DELETEEelentForChangeset:(NSNumber *)changeset
{
    DDXMLElement *nodeXML = [super DELETEEelentForChangeset:changeset];
    return [self addLatLon:nodeXML];
}

- (DDXMLElement *)PUTElementForChangeset:(NSNumber *)changeset
{
    DDXMLElement *nodeXML = [super PUTElementForChangeset:changeset];
    return [self addLatLon:nodeXML];
}

- (DDXMLElement *)addLatLon:(DDXMLElement *)nodeXML
{
    [nodeXML addAttributeWithName:@"lat" stringValue:[@(self.latitude) stringValue]];
    [nodeXML addAttributeWithName:@"lon" stringValue:[@(self.longitude) stringValue]];
    return nodeXML;
}

#pragma NSCopying Methods

- (id)copyWithZone:(NSZone *)zone
{
    OSMKNode *node = [super copyWithZone:zone];
    node.coordinate = self.coordinate;
    
    return node;
}


@end

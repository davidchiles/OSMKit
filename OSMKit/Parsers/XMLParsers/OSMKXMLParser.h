//
//  OSMKXMLParser.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKParser.h"

extern NSString *const OSMKNodeElementName;
extern NSString *const OSMKWayElementName;
extern NSString *const OSMKRelationElementName;
extern NSString *const OSMKTagElementName;
extern NSString *const OSMKWayNodeElementName;
extern NSString *const OSMKRelationMemberElementName;
extern NSString *const OSMKUserElementName;
extern NSString *const OSMKNoteElementName;

@interface OSMKXMLParser : OSMKParser

- (void)parseXMLData:(NSData *)xmlData;

@end

//
//  OSMKNSJSONSerializationParser.h
//  OSMKit
//
//  Created by David Chiles on 4/21/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKParser.h"

@interface OSMKNSJSONSerializationParser : OSMKParser

- (void)parseJSONData:(NSData *)data;
- (void)parseJSONDictionary:(NSDictionary *)dictionary;
- (void)parseJSONStream:(NSInputStream *)stream;

@end

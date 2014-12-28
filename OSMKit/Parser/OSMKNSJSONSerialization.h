//
//  OSMKNSJSONSerializationParser.h
//  OSMKit
//
//  Created by David Chiles on 4/21/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKParser.h"

@interface OSMKNSJSONSerialization : NSObject <OSMKParserProtocol>

- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithStream:(NSInputStream *)inputStream;

@end

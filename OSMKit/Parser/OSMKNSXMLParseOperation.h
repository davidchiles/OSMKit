//
//  OSMKNSXMLParser.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKXMLParseOperation.h"

@interface OSMKNSXMLParseOperation: OSMKParseOperation

- (instancetype)initWithStream:(NSInputStream *)inputStream;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithXMLParser:(NSXMLParser *)parser;

@end

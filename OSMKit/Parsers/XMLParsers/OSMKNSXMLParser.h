//
//  OSMKNSXMLParser.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKXMLParser.h"

@interface OSMKNSXMLParser : OSMKXMLParser

- (void)parseOSMStream:(NSInputStream *)inputStream;
- (void)parseOSMUrl:(NSURL *)url;

@end

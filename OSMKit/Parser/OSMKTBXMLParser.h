//
//  OSMKTBXMLParser.h
//  Pods
//
//  Created by David Chiles on 12/28/14.
//
//

#import <Foundation/Foundation.h>

#import "OSMKParser.h"

@interface OSMKTBXMLParser : NSObject <OSMKParserProtocol>

- (instancetype)initWithData:(NSData *)data error:(NSError **)error;

@end

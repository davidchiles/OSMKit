//
//  OSMKRequestSerializer.h
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "AFURLRequestSerialization.h"

@interface OSMKRequestSerializer : AFHTTPRequestSerializer

- (instancetype)initWithConsumerKey:(NSString *)consumerKey
                         privateKey:(NSString *)privateKey
                              token:(NSString *)token
                        tokenSecret:(NSString *)tokenSecret;

@end

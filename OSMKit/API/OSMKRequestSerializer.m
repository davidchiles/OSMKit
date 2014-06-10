//
//  OSMKRequestSerializer.m
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKRequestSerializer.h"

#import "GTMOAuthAuthentication.h"

@interface OSMKRequestSerializer ()

@property (nonatomic, strong) GTMOAuthAuthentication *token;

@end

@implementation OSMKRequestSerializer

- (instancetype)initWithConsumerKey:(NSString *)consumerKey privateKey:(NSString *)privateKey token:(NSString *)token tokenSecret:(NSString *)tokenSecret;
{
    if (self = [self init]) {
        self.token = [[GTMOAuthAuthentication alloc] initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1 consumerKey:consumerKey privateKey:privateKey];
        self.token.token = token;
        self.token.tokenSecret = tokenSecret;
    }
    return self;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest * request = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    
    if (self.token) {
        [self.token authorizeRequest:request];
    }
    
    return request;
}

@end

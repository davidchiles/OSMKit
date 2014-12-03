//
//  OSMKTestData.h
//  OSMKit
//
//  Created by David Chiles on 12/2/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSMKTestObject :NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic) NSInteger nodeCount;
@property (nonatomic) NSInteger wayCount;
@property (nonatomic) NSInteger relationCount;
@property (nonatomic) NSInteger noteCount;
@property (nonatomic) NSInteger userCount;

- (instancetype)initWithData:(NSData *)data;

+ (instancetype)testObjectWithData:(NSData *)data;

@end

@interface OSMKTestData : NSObject

- (void)enumerateXMLDataSources:(void (^)(OSMKTestObject *testObject, BOOL *stop))block;
- (void)enumerateJSONDataSources:(void (^)(OSMKTestObject *testObject, BOOL *stop))block;

@end

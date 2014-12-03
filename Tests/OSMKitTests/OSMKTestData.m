//
//  OSMKTestData.m
//  OSMKit
//
//  Created by David Chiles on 12/2/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKTestData.h"

@implementation OSMKTestObject

- (instancetype)init
{
    if (self = [super init]) {
        self.nodeCount = 0;
        self.wayCount = 0;
        self.relationCount = 0;
        self.userCount = 0;
        self.noteCount = 0;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data
{
    if (self = [self init]) {
        self.data = data;
    }
    return self;
}

+ (instancetype)testObjectWithData:(NSData *)data
{
    NSAssert([data length] > 0, @"Data cannote be empty");
    return [[self alloc] initWithData:data];
}

@end

@interface OSMKTestData ()

@property (nonatomic, strong) NSArray *xmlDataArray;
@property (nonatomic, strong) NSArray *jsonDataArray;

@end

@implementation OSMKTestData

- (instancetype)init
{
    if (self = [super init]) {
        
        self.xmlDataArray = @[];
        self.jsonDataArray = @[];
        
        OSMKTestObject *testObject = [OSMKTestObject testObjectWithData:[self dataForResource:@"berkeley" ofType:@"osm"]];
        testObject.nodeCount = 51654;
        testObject.wayCount = 6594;
        testObject.relationCount = 231;
        
        self.xmlDataArray = [self.xmlDataArray arrayByAddingObject:testObject];
        
        testObject = [OSMKTestObject testObjectWithData:[self dataForResource:@"small_berkeley" ofType:@"osm"]];
        testObject.nodeCount = 1625;
        testObject.wayCount = 254;
        testObject.relationCount = 70;
        
        self.xmlDataArray = [self.xmlDataArray arrayByAddingObject:testObject];
        
        testObject = [OSMKTestObject testObjectWithData:[self dataForResource:@"user" ofType:@"osm"]];
        testObject.userCount = 1;
        
        self.xmlDataArray = [self.xmlDataArray arrayByAddingObject:testObject];
        
        testObject = [OSMKTestObject testObjectWithData:[self dataForResource:@"notes" ofType:@"xml"]];
        testObject.noteCount = 100;
        
        self.xmlDataArray = [self.xmlDataArray arrayByAddingObject:testObject];
        
        //JSON
        testObject = [OSMKTestObject testObjectWithData:[self dataForResource:@"notes" ofType:@"json"]];
        testObject.noteCount = 100;
        
        self.jsonDataArray = [self.jsonDataArray arrayByAddingObject:testObject];
        
        testObject = [OSMKTestObject testObjectWithData:[self dataForResource:@"note" ofType:@"json"]];
        testObject.noteCount = 1;
        
        self.jsonDataArray = [self.jsonDataArray arrayByAddingObject:testObject];
    }
    return self;
}

- (NSData *)dataForResource:(NSString *)resource ofType:(NSString *)type
{
    NSString *path = [[NSBundle mainBundle] pathForResource:resource ofType:type];
    if (path) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        return data;
    }
    return nil;
}

- (void)addPathForResource:(NSString *)resource ofType:(NSString *)type
{
    NSString *path = [[NSBundle mainBundle] pathForResource:resource ofType:type];
    if (path) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {
            if ([type isEqualToString:@"json"]) {
                self.jsonDataArray = [self.jsonDataArray arrayByAddingObject:data];
            }
            else {
                self.xmlDataArray = [self.xmlDataArray arrayByAddingObject:data];
            }
        }
    }
}
- (void)enumerateJSONDataSources:(void (^)(OSMKTestObject *, BOOL *))block
{
    if (!block) {
        return;
    }
    
    [self.jsonDataArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[OSMKTestObject class]]) {
            block(obj,stop);
        }
    }];
}

- (void)enumerateXMLDataSources:(void (^)(OSMKTestObject *, BOOL *))block
{
    if (!block) {
        return;
    }
    
    [self.xmlDataArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[OSMKTestObject class]]) {
            block(obj,stop);
        }
    }];
}

@end

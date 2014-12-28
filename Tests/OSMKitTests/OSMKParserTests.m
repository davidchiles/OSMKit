//
//  OSMKitTests.m
//  OSMKitTests
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSMKNSJSONSerialization.h"
#import "FMDB.h"
#import "OSMKTBXMLParser.h"
#import "OSMKTestData.h"

@interface OSMKParserTests : XCTestCase

@property (nonatomic, strong) OSMKTestData *testData;

@end

@implementation OSMKParserTests

- (void)setUp
{
    [super setUp];
    
    self.testData = [[OSMKTestData alloc] init];
}

- (void)testTBXMLParser
{
    [self.testData enumerateXMLDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        [self testTBXMLParseNodesWithTestObject:testObject];
        [self testTBXMLParseWaysWithTestObject:testObject];
        [self testTBXMLParseRelationsWithTestObject:testObject];
        [self testTBXMLParseNotesWithTestObject:testObject];
        [self testTBXMLParseUsersWithTestObject:testObject];
    }];
}

- (void)testTBXMLParseNodesWithTestObject:(OSMKTestObject *)testObject
{
    NSError *error = nil;
    OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:testObject.data error:&error];
    NSArray *nodes = [parser parseNodes];
    XCTAssertEqual([nodes count], testObject.nodeCount, @"Node not equal");
    XCTAssertNil(error,@"Found Error");
}

- (void)testTBXMLParseWaysWithTestObject:(OSMKTestObject *)testObject
{
    NSError *error = nil;
    OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:testObject.data error:&error];
    NSArray *ways = [parser parseWays];
    XCTAssertEqual([ways count], testObject.wayCount, @"Way count not equal");
    XCTAssertNil(error,@"Found Error");
}

- (void)testTBXMLParseRelationsWithTestObject:(OSMKTestObject *)testObject
{
    NSError *error = nil;
    OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:testObject.data error:&error];
    NSArray *relations = [parser parseRelations];
    
    XCTAssertEqual([relations count], testObject.relationCount, @"Relations count not equal");
    XCTAssertNil(error,@"Found Error");
}

- (void)testTBXMLParseUsersWithTestObject:(OSMKTestObject *)testObject
{
    NSError *error = nil;
    OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:testObject.data error:&error];
    NSArray *users = [parser parseUsers];
    
    XCTAssertEqual([users count], testObject.userCount, @"Relations count not equal");
    XCTAssertNil(error,@"Found Error");
}

- (void)testTBXMLParseNotesWithTestObject:(OSMKTestObject *)testObject
{
    NSError *error = nil;
    OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:testObject.data error:&error];
    
    NSArray *notes = [parser parseNotes];
    XCTAssertEqual([notes count], testObject.noteCount, @"Relations count not equal");
    XCTAssertNil(error,@"Found Error");
}

- (void)testTBXMLPerformance {
    [self measureBlock:^{
        [self.testData enumerateXMLDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
            OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:testObject.data error:nil];
            NSArray *nodes = [parser parseNodes];
            NSArray *ways = [parser parseWays];
            NSArray *relations = [parser parseRelations];
            NSArray *notes = [parser parseNotes];
            NSArray *users = [parser parseUsers];
            
            XCTAssertEqual([nodes count], testObject.nodeCount, @"Node count not equal");
            XCTAssertEqual([ways count], testObject.wayCount, @"Way count not equal");
            XCTAssertEqual([relations count], testObject.relationCount, @"Relation count not equal");
            XCTAssertEqual([users count], testObject.userCount, @"User count not equal");
            XCTAssertEqual([notes count], testObject.noteCount, @"Note count not equal");
        }];
        
        
    }];
}

- (void)testNSJSONSerializationParser
{
    [self.testData enumerateJSONDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        OSMKNSJSONSerialization *serializer = [[OSMKNSJSONSerialization alloc] initWithData:testObject.data];
        NSArray *notes = [serializer parseNotes];
        XCTAssertEqual([notes count],testObject.noteCount);
    }];
}

- (void)testNSJSONPerformance {
    [self measureBlock:^{
        [self testNSJSONSerializationParser];
    }];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end

//
//  OSMKitTests.m
//  OSMKitTests
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSMKNSXMLParseOperation.h"
#import "OSMKTBXMLParseOperation.h"
#import "OSMKSpatiaLiteStorage.h"
#import "OSMKNSJSONSerializationOperation.h"
#import "OSMKOnoXMLParseOperation.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

#import "OSMKTestData.h"

static const double timeOut = 30;

@interface OSMKParserTests : XCTestCase

@property (nonatomic, strong) OSMKTestData *testData;

@property (nonatomic, strong) NSOperationQueue *parseOperationQueue;

@end

@implementation OSMKParserTests

- (void)setUp
{
    [super setUp];
    
    self.testData = [OSMKTestData new];
    
    
    self.parseOperationQueue = [NSOperationQueue new];
    self.parseOperationQueue.maxConcurrentOperationCount = 1;
}

- (void)testNSXMLParser
{
    [self.testData enumerateXMLDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        OSMKNSXMLParseOperation *parseOperation = [[OSMKNSXMLParseOperation alloc] initWithData:testObject.data];
        [self testOperation:parseOperation withTestObject:testObject];
    }];
}

- (void)testNSXMLPerformance {
    [self measureBlock:^{
        [self testNSXMLParser];
    }];
    
}

- (void)testTBXMLParser
{
    [self.testData enumerateXMLDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        OSMKTBXMLParseOperation *parseOperation = [[OSMKTBXMLParseOperation alloc] initWithData:testObject.data];
        [self testOperation:parseOperation withTestObject:testObject];
    }];
}

- (void)testTBXMLPerformance {
    [self measureBlock:^{
        [self testTBXMLParser];
        
    }];
}

- (void)testOnoXMLParseOperation
{
    [self.testData enumerateXMLDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        OSMKOnoXMLParseOperation *parseOperation = [[OSMKOnoXMLParseOperation alloc] initWithData:testObject.data];
        [self testOperation:parseOperation withTestObject:testObject];
    }];
}

- (void)testOnoXMLPerformance {
    [self measureBlock:^{
        [self testOnoXMLParseOperation];
    }];
}


- (void)testNSJSONSerializationParser
{
    [self.testData enumerateJSONDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        OSMKNSJSONSerializationOperation *parseOperation = [[OSMKNSJSONSerializationOperation alloc] initWithData:testObject.data];
        [self testOperation:parseOperation withTestObject:testObject];
    }];
}

- (void)testNSJSONPerformance {
    [self measureBlock:^{
        [self testNSJSONSerializationParser];
    }];
    
}

- (void)testOperation:(OSMKParseOperation *)parseOperation withTestObject:(OSMKTestObject *)testObject
{
    XCTestExpectation *elementExpectation = [self expectationWithDescription:@"Parsed Elements"];
    XCTestExpectation *notesExpectation = [self expectationWithDescription:@"Parsed Notes"];
    XCTestExpectation *usersExpectation = [self expectationWithDescription:@"Parsed Users"];
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Completed"];
    
    [parseOperation setElementsCompletionBlock:^void ((NSArray *nodes, NSArray *ways, NSArray *relations)) {
        XCTAssertTrue([nodes count] == testObject.nodeCount);
        XCTAssertTrue([ways count] == testObject.wayCount);
        XCTAssertTrue([relations count] == testObject.relationCount);
        [elementExpectation fulfill];
    }];
    [parseOperation setNotesCompletionBlock:^void ((NSArray *notes)) {
        XCTAssertTrue([notes count] == testObject.noteCount);
        [notesExpectation fulfill];
    }];
    
    [parseOperation setUsersCompletionBlock:^void ((NSArray *users)) {
        XCTAssertTrue([users count] == testObject.userCount);
        [usersExpectation fulfill];
    }];
    
    [parseOperation setCompletionBlock:^{
        [completionExpectation fulfill];
    }];
    
    [self.parseOperationQueue addOperation:parseOperation];
    [self waitForExpectationsWithTimeout:timeOut handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

/*
- (void)testSpatiaLiteStorageDelegateMethods
{
    TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:3];
    
    OSMKStorageDelegateTest *storageDelegate = [[OSMKStorageDelegateTest alloc] init];
    OSMKParseCompletionBlock completionBlock = ^void(void) {
        [monitor signal];
    };
    storageDelegate.completionBlock = completionBlock;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths firstObject];
    NSString *dbPath = [docPath stringByAppendingPathComponent:@"db.sqlite"];
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    OSMKSpatiaLiteStorage * spatiaLiteStorage = [[OSMKSpatiaLiteStorage alloc] initWithdatabaseFilePath:dbPath delegate:storageDelegate delegateQueue:nil];
    
    [spatiaLiteStorage importXMLData:self.osmFileData];
    [spatiaLiteStorage importXMLData:self.notesXMLFileData];
    [spatiaLiteStorage importXMLData:self.userFileData];
    
    [monitor waitWithTimeout:10000];
    
    OSMKNode *node = [spatiaLiteStorage nodeWithOsmId:282832042];
    OSMKWay *way = [spatiaLiteStorage wayWithOsmId:6336803];
    OSMKRelation *relation = [spatiaLiteStorage relationWithOsmId:2602922];
    OSMKUser *user = [spatiaLiteStorage userWithOsmId:355617];
    OSMKNote *note = [spatiaLiteStorage noteWithOsmId:153884];
    
    XCTAssertNotNil(node, @"Node Not Found");
    XCTAssertNotNil(way, @"Way Not Found");
    XCTAssertNotNil(relation, @"Relation Not Found");
    XCTAssertNotNil(user, @"User Not Found");
    XCTAssertNotNil(note, @"Note Not Found");
    
    XCTAssert(storageDelegate.nodesCount == nodesCount, @"FOUND: %d/%d",storageDelegate.nodesCount,nodesCount);
    XCTAssert(storageDelegate.waysCount == waysCount, @"FOUND: %d/%d", storageDelegate.waysCount, waysCount);
    XCTAssert(storageDelegate.relationsCount == relationsCount, @"FOUND: %d/%d", storageDelegate.relationsCount,relationsCount);
    XCTAssert(storageDelegate.usersCount == 1, @"FOUND: %d/1",storageDelegate.usersCount);
    XCTAssert(storageDelegate.notesCount == 100, @"FOUND: %d/100",storageDelegate.notesCount);
}

- (void)testSpatiaLiteStorage
{
    TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:3];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths firstObject];
    NSString *dbPath = [docPath stringByAppendingPathComponent:@"db.sqlite"];
    
    __block NSInteger foundNodeCount = 0;
    __block NSInteger foundWayCount = 0;
    __block NSInteger foundRelationCount =0;
    __block NSInteger foundUserCount = 0;
    __block NSInteger foundNoteCount = 0;
    
    OSMKStorageDelegateTest *storageDelegate = [[OSMKStorageDelegateTest alloc] init];
    OSMKParseCompletionBlock completionBlock = ^void(void) {
        
        FMDatabaseQueue *queue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
        
        [queue inDatabase:^(FMDatabase *db) {
            FMResultSet *result = [db executeQuery:@"SELECT COUNT(*) AS count FROM nodes"];
            while ([result next]) {
                foundNodeCount = [result intForColumn:@"count"];
            }
            
            result = [db executeQuery:@"SELECT COUNT(*) AS count FROM ways"];
            while ([result next]) {
                foundWayCount = [result intForColumn:@"count"];
            }
            
            result = [db executeQuery:@"SELECT COUNT(*) AS count FROM relations"];
            while ([result next]) {
                foundRelationCount = [result intForColumn:@"count"];
            }
            
            result = [db executeQuery:@"SELECT COUNT(*) AS count FROM users"];
            while ([result next]) {
                foundUserCount = [result intForColumn:@"count"];
            }
            
            result = [db executeQuery:@"SELECT COUNT(*) AS count FROM notes"];
            while ([result next]) {
                foundNoteCount = [result intForColumn:@"count"];
            }
            
            
        }];
        
        
        [monitor signal];
    };
    storageDelegate.completionBlock = completionBlock;
    
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    OSMKSpatiaLiteStorage * spatiaLiteStorage = [[OSMKSpatiaLiteStorage alloc] initWithdatabaseFilePath:dbPath delegate:storageDelegate delegateQueue:nil];
    
    [spatiaLiteStorage importXMLData:self.osmFileData];
    [spatiaLiteStorage importXMLData:self.notesXMLFileData];
    [spatiaLiteStorage importXMLData:self.userFileData];
    
    [monitor waitWithTimeout:10000];
    
    XCTAssert(foundNodeCount == nodesCount, @"FOUND: %d/%d",storageDelegate.nodesCount,nodesCount);
    XCTAssert(foundWayCount == waysCount, @"FOUND: %d/%d", storageDelegate.waysCount, waysCount);
    XCTAssert(foundRelationCount == relationsCount, @"FOUND: %d/%d", storageDelegate.relationsCount,relationsCount);
    XCTAssert(foundUserCount == 1, @"FOUND: %d/1",storageDelegate.usersCount);
    XCTAssert(foundNoteCount == 100, @"FOUND: %d/100",storageDelegate.notesCount);
    
}
*/
- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end

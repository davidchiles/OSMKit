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
#import "OSMKStorageDelegateTest.h"
#import "OSMKNSJSONSerializationParseOperation.h"
#import "TRVSMonitor.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

static const int nodesCount = 1625; //51654
static const int waysCount = 254; //6594
static const int relationsCount = 70; //231

static const double timeOut = 1000.0;

@interface OSMKitTests : XCTestCase

@property (nonatomic, strong) NSData *osmFileData;
@property (nonatomic, strong) NSData *userFileData;
@property (nonatomic, strong) NSData *notesJSONFileData;
@property (nonatomic, strong) NSData *noteJSONFileData;
@property (nonatomic, strong) NSData *notesXMLFileData;

@property (nonatomic, strong) NSOperationQueue *parseOperationQueue;

@end

@implementation OSMKitTests

- (void)setUp
{
    [super setUp];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"small_berkeley" ofType:@"osm"];
    self.osmFileData = [NSData dataWithContentsOfFile:path];
    
    NSString *userPath = [[NSBundle mainBundle] pathForResource:@"user" ofType:@"osm"];
    self.userFileData = [NSData dataWithContentsOfFile:userPath];
    
    NSString *notesJSONPath = [[NSBundle mainBundle] pathForResource:@"notes" ofType:@"json"];
    self.notesJSONFileData = [NSData dataWithContentsOfFile:notesJSONPath];
    
    NSString *noteJSONPath = [[NSBundle mainBundle] pathForResource:@"note" ofType:@"json"];
    self.noteJSONFileData = [NSData dataWithContentsOfFile:noteJSONPath];
    
    NSString *notesXMLPath = [[NSBundle mainBundle] pathForResource:@"notes" ofType:@"xml"];
    self.notesXMLFileData = [NSData dataWithContentsOfFile:notesXMLPath];
    
    self.parseOperationQueue = [[NSOperationQueue alloc] init];
}

- (void)testNSXMLParser
{
    [self testNSXMLWithData:self.osmFileData nodes:nodesCount ways:waysCount relations:relationsCount notes:0 users:0];
    [self testNSXMLWithData:self.userFileData nodes:0 ways:0 relations:0 notes:0 users:1];
    [self testNSXMLWithData:self.notesXMLFileData nodes:0 ways:0 relations:0 notes:100 users:0];
}

- (void)testNSXMLWithData:(NSData *)data nodes:(NSUInteger)nodeCount ways:(NSUInteger)wayCount relations:(NSUInteger)relationCount notes:(NSUInteger)noteCount users:(NSUInteger)userCount
{
    XCTestExpectation *elementExpectation = [self expectationWithDescription:@"Parsed Elements"];
    XCTestExpectation *notesExpectation = [self expectationWithDescription:@"Parsed Notes"];
    XCTestExpectation *usersExpectation = [self expectationWithDescription:@"Parsed Users"];
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Completed"];
    
    OSMKNSXMLParseOperation *elementOperation = [[OSMKNSXMLParseOperation alloc] initWithData:data];
    [elementOperation setElementsCompletionBlock:^void ((NSArray *nodes, NSArray *ways, NSArray *relations, NSError *error)) {
        XCTAssertTrue([nodes count] == nodeCount);
        XCTAssertTrue([ways count] == wayCount);
        XCTAssertTrue([relations count] == relationCount);
        XCTAssertNil(error);
        [elementExpectation fulfill];
    }];
    [elementOperation setNotesCompletionBlock:^void ((NSArray *notes, NSError *error)) {
        XCTAssertTrue([notes count] == noteCount);
        XCTAssertNil(error);
        [notesExpectation fulfill];
    }];
    
    [elementOperation setUsersCompletionBlock:^void ((NSArray *users, NSError *error)) {
        XCTAssertTrue([users count] == userCount);
        XCTAssertNil(error);
        [usersExpectation fulfill];
    }];
    
    [elementOperation setCompletionBlock:^{
        [completionExpectation fulfill];
    }];
    
    [self.parseOperationQueue addOperation:elementOperation];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}


- (void)testTBXMLParser
{
    [self testTBXMLWithData:self.osmFileData nodes:nodesCount ways:waysCount relations:relationsCount notes:0 users:0];
    [self testTBXMLWithData:self.userFileData nodes:0 ways:0 relations:0 notes:0 users:1];
    [self testTBXMLWithData:self.notesXMLFileData nodes:0 ways:0 relations:0 notes:100 users:0];
}

- (void)testTBXMLWithData:(NSData *)data nodes:(NSUInteger)nodeCount ways:(NSUInteger)wayCount relations:(NSUInteger)relationCount notes:(NSUInteger)noteCount users:(NSUInteger)userCount
{
    XCTestExpectation *elementExpectation = [self expectationWithDescription:@"Parsed Elements"];
    XCTestExpectation *notesExpectation = [self expectationWithDescription:@"Parsed Notes"];
    XCTestExpectation *usersExpectation = [self expectationWithDescription:@"Parsed Users"];
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Completed"];
    
    OSMKTBXMLParseOperation *elementOperation = [[OSMKTBXMLParseOperation alloc] initWithData:data];
    [elementOperation setElementsCompletionBlock:^void ((NSArray *nodes, NSArray *ways, NSArray *relations, NSError *error)) {
        XCTAssertTrue([nodes count] == nodeCount);
        XCTAssertTrue([ways count] == wayCount);
        XCTAssertTrue([relations count] == relationCount);
        XCTAssertNil(error);
        [elementExpectation fulfill];
    }];
    [elementOperation setNotesCompletionBlock:^void ((NSArray *notes, NSError *error)) {
        XCTAssertTrue([notes count] == noteCount);
        XCTAssertNil(error);
        [notesExpectation fulfill];
    }];
    
    [elementOperation setUsersCompletionBlock:^void ((NSArray *users, NSError *error)) {
        XCTAssertTrue([users count] == userCount);
        XCTAssertNil(error);
        [usersExpectation fulfill];
    }];
    
    [elementOperation setCompletionBlock:^{
        [completionExpectation fulfill];
    }];
    
    [self.parseOperationQueue addOperation:elementOperation];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}



- (void)testNSJSONSerializationParser
{
    TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:2];
    
    
//    OSMKNSJSONSerializationParser * jsonParser = [[OSMKNSJSONSerializationParser alloc] initWithDelegate:parserDelegate delegateQueue:nil];
//    [jsonParser parseJSONData:self.notesJSONFileData];
//    [jsonParser parseJSONData:self.noteJSONFileData];
//    
//    
//    [monitor waitWithTimeout:timeOut];
    
    //XCTAssert(parserDelegate.notesCount == 101);
}

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

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end

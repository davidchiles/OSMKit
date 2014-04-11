//
//  OSMKitTests.m
//  OSMKitTests
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSMKNSXMLParser.h"
#import "OSMKTBXMLParser.h"
#import "OSMKSpatiaLiteStorage.h"
#import "OSMKParserDelegateTest.h"
#import "OSMKStorageDelegateTest.h"
#import "OSMKNSJSONSerializationParser.h"
#import "TRVSMonitor.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

static const int nodesCount = 1625; //51654
static const int waysCount = 254; //6594
static const int relationsCount = 70; //231

static const double timeOut = 1000.0;

static const int tagsCount = 375;

@interface OSMKitTests : XCTestCase

@property (nonatomic, strong) NSData *osmFileData;
@property (nonatomic, strong) NSData *userFileData;
@property (nonatomic, strong) NSData *notesJSONFileData;
@property (nonatomic, strong) NSData *noteJSONFileData;
@property (nonatomic, strong) NSData *notesXMLFileData;

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
    
    
}

- (void)testNSXMLParser
{
    TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:3];
    
    OSMKParserDelegateTest *parserDelegate = [[OSMKParserDelegateTest alloc] init];
    OSMKParseCompletionBlock completionBlock = ^void(void) {
        [monitor signal];
    };
    parserDelegate.completionBlock = completionBlock;
    
    
    OSMKNSXMLParser *parser = [[OSMKNSXMLParser alloc] initWithDelegate:parserDelegate delegateQueue:nil];
    [parser parseXMLData:self.osmFileData];
    [parser parseXMLData:self.userFileData];
    [parser parseXMLData:self.notesXMLFileData];
    
    
    [monitor waitWithTimeout:1000.0];
    
    XCTAssert(parserDelegate.nodesCount == nodesCount);
    XCTAssert(parserDelegate.waysCount == waysCount);
    XCTAssert(parserDelegate.relationsCount == relationsCount);
    XCTAssert(parserDelegate.usersCount == 1);
    XCTAssert(parserDelegate.notesCount == 100);
}

- (void)testTBXMLParser
{
    TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:3];
    
    OSMKParserDelegateTest *parserDelegate = [[OSMKParserDelegateTest alloc] init];
    OSMKParseCompletionBlock completionBlock = ^void(void) {
        [monitor signal];
    };
    parserDelegate.completionBlock = completionBlock;
    
    
    OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithDelegate:parserDelegate delegateQueue:nil];
    [parser parseXMLData:self.osmFileData];
    [parser parseXMLData:self.userFileData];
    [parser parseXMLData:self.notesXMLFileData];
    
    [monitor waitWithTimeout:timeOut];
    
    XCTAssert(parserDelegate.nodesCount == nodesCount);
    XCTAssert(parserDelegate.waysCount == waysCount);
    XCTAssert(parserDelegate.relationsCount == relationsCount);
    XCTAssert(parserDelegate.usersCount == 1);
    XCTAssert(parserDelegate.notesCount == 100);
}

- (void)testNSJSONSerializationParser
{
    TRVSMonitor *monitor = [[TRVSMonitor alloc] initWithExpectedSignalCount:2];
    OSMKParserDelegateTest *parserDelegate = [[OSMKParserDelegateTest alloc] init];
    OSMKParseCompletionBlock completionBlock = ^void(void) {
        [monitor signal];
    };
    parserDelegate.completionBlock = completionBlock;
    
    OSMKNSJSONSerializationParser * jsonParser = [[OSMKNSJSONSerializationParser alloc] initWithDelegate:parserDelegate delegateQueue:nil];
    [jsonParser parseJSONData:self.notesJSONFileData];
    [jsonParser parseJSONData:self.noteJSONFileData];
    
    
    [monitor waitWithTimeout:timeOut];
    
    XCTAssert(parserDelegate.notesCount == 101);
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

//
//  OSMKStorageTests.m
//  OSMKit
//
//  Created by David Chiles on 12/2/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSMKTBXMLParseOperation.h"
#import "OSMKSpatiaLiteStorage.h"
#import "OSMKSpatiaLiteStorageSaveOperation.h"
#import "OSMKTestData.h"
#import "FMDB.h"

@interface OSMKStorageTests : XCTestCase

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) OSMKTestData *testData;

@property (nonatomic, strong) OSMKSpatiaLiteStorage *database;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end

@implementation OSMKStorageTests

- (void)setUp {
    [super setUp];
    
    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"db.sqlite"];
    
    self.database = [OSMKSpatiaLiteStorage spatiaLiteStorageWithFilePath:self.filePath overwrite:NO];
    self.databaseQueue = [[FMDatabaseQueue alloc] initWithPath:self.filePath];
    
    self.testData = [OSMKTestData new];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
}

- (void)tearDown {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
    }
    
    [super tearDown];
}

- (void)testSpatiaLiteStorage {
    [self.testData enumerateXMLDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        OSMKTBXMLParseOperation *parseOperation = [[OSMKTBXMLParseOperation alloc] initWithData:testObject.data];
        [self testSpatiaLiteWithParseOperation:parseOperation withTestObject:testObject];
    }];
    
}

- (void)testSpatiaLiteWithParseOperation:(OSMKParseOperation *)parseOperation withTestObject:(OSMKTestObject *)testObject
{
    XCTestExpectation *elementExpectation = [self expectationWithDescription:@"Saved Elements"];
    XCTestExpectation *notesExpectation = [self expectationWithDescription:@"Saved Notes"];
    XCTestExpectation *usersExpectation = [self expectationWithDescription:@"Saved Users"];
    XCTestExpectation *elementsCompletionExpectation = [self expectationWithDescription:@"Completed Elements"];
    XCTestExpectation *notesCompletionExpectation = [self expectationWithDescription:@"Completed Notes"];
    XCTestExpectation *usersCompletionExpectation = [self expectationWithDescription:@"Completed Users"];
    
    [parseOperation setElementsCompletionBlock:^void ((NSArray *nodes, NSArray *ways, NSArray *relations)) {
        
        OSMKSpatiaLiteStorageSaveOperation *storageOperation = [[OSMKSpatiaLiteStorageSaveOperation alloc] initWithDatabaseQueue:self.databaseQueue nodes:nodes ways:ways relations:relations];
        [storageOperation setElementsCompletionBlock:^void ((NSArray *nodes, NSArray *ways, NSArray *relations)) {
            XCTAssertTrue([nodes count] == testObject.nodeCount);
            XCTAssertTrue([ways count] == testObject.wayCount);
            XCTAssertTrue([relations count] == testObject.relationCount);
            [elementExpectation fulfill];
        }];
        [storageOperation setCompletionBlock:^{
            [elementsCompletionExpectation fulfill];
        }];
        [self.operationQueue addOperation:storageOperation];
    }];
    [parseOperation setNotesCompletionBlock:^void ((NSArray *notes)) {
        OSMKSpatiaLiteStorageSaveOperation *storageOperation = [[OSMKSpatiaLiteStorageSaveOperation alloc] initWithDatabaseQueue:self.databaseQueue notes:notes];
        [storageOperation setNotesCompletionBlock:^void ((NSArray *notes)) {
            XCTAssertTrue([notes count] == testObject.noteCount);
            [notesExpectation fulfill];
        }];
        [storageOperation setCompletionBlock:^{
            [notesCompletionExpectation fulfill];
        }];
        [self.operationQueue addOperation:storageOperation];
    }];
    
    [parseOperation setUsersCompletionBlock:^void ((NSArray *users)) {
        OSMKSpatiaLiteStorageSaveOperation *storageOperation = [[OSMKSpatiaLiteStorageSaveOperation alloc] initWithDatabaseQueue:self.databaseQueue users:users];
        [storageOperation setNotesCompletionBlock:^void ((NSArray *users)) {
            XCTAssertTrue([users count] == testObject.userCount);
            [usersExpectation fulfill];
        }];
        [storageOperation setCompletionBlock:^{
            [usersCompletionExpectation fulfill];
        }];
        [self.operationQueue addOperation:storageOperation];
    }];
    
    [self.operationQueue addOperation:parseOperation];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
    
}

- (void)testSpatiaLiteStoragePerformance {
    [self measureBlock:^{
        [self testSpatiaLiteStorage];
    }];
}

@end

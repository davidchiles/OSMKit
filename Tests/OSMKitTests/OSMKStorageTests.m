//
//  OSMKStorageTests.m
//  OSMKit
//
//  Created by David Chiles on 12/2/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSMKSpatiaLiteStorage.h"
#import "OSMKTestData.h"
#import "FMDB.h"
#import "FMDatabase+OSMKitSpatiaLite.h"
#import "SpatialDatabaseQueue.h"
#import "OSMKTBXMLParser.h"

@interface OSMKStorageTests : XCTestCase

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) OSMKTestData *testData;

@property (nonatomic, strong) OSMKSpatiaLiteStorage *database;
@property (nonatomic, strong) SpatialDatabaseQueue *databaseQueue;

@end

@implementation OSMKStorageTests

- (void)setUp {
    [super setUp];
    
    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"db.sqlite"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
    }
    
    NSLog(@"File Path: %@",self.filePath);
    
    self.database = [OSMKSpatiaLiteStorage spatiaLiteStorageWithFilePath:self.filePath overwrite:NO];
    self.databaseQueue = [[SpatialDatabaseQueue alloc] initWithPath:self.filePath];
    
    self.testData = [[OSMKTestData alloc] init];
    
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSpatiaLiteStorage {
    
    [self.testData enumerateXMLDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        NSError *error = nil;
        OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:testObject.data error:&error];
        XCTAssertNil(error,@"Error parsing");
        
        __block NSArray *nodes = [parser parseNodes];
        
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [nodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSError *dbError = nil;
                BOOL result = [db osmk_saveNode:obj error:&dbError];
                XCTAssertTrue(result == YES,@"Error Saving Node %@",obj);
                XCTAssertNil(dbError,@"Error saving Node");
            }];
        }];
        
        __block NSArray *ways = [parser parseWays];
        
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [ways enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSError *dbError = nil;
                BOOL result = [db osmk_saveWay:obj error:&dbError];
                XCTAssertTrue(result == YES,@"Error Saving way %@",obj);
                XCTAssertNil(dbError,@"Error saving way");
            }];
        }];
        
        __block NSArray *relations = [parser parseRelations];
        
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [relations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSError *dbError = nil;
                BOOL result = [db osmk_saveRelation:obj error:&dbError];
                XCTAssertTrue(result == YES,@"Error Saving Relation %@",obj);
                XCTAssertNil(dbError,@"Error saving Relation");
            }];
        }];
        
        __block NSArray *notes = [parser parseNotes];
        
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [notes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSError *dbError = nil;
                BOOL result = [db osmk_saveNote:obj error:&dbError];
                XCTAssertTrue(result == YES,@"Error Saving Note %@",obj);
                XCTAssertNil(dbError,@"Error saving Note");
            }];
        }];
        
        __block NSArray *users = [parser parseUsers];
        
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [users enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSError *dbError = nil;
                BOOL result = [db osmk_saveUser:obj error:&dbError];
                XCTAssertTrue(result == YES,@"Error Saving User %@",obj);
                XCTAssertNil(dbError,@"Error saving User");
            }];
        }];
    }];
    
}

//Test that all ways have geometry

- (void)testwayNodeUnique
{
    NSString *tagInsertString = [NSString stringWithFormat:@"INSERT INTO way_node (way_id, node_id, local_order) VALUES (?,?,?)"];
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        BOOL result = [db executeUpdate:tagInsertString,@(1),@(11),@(0)];
        result = [db executeUpdate:tagInsertString,@(1),@(11),@(0)];
        result = [db executeUpdate:tagInsertString,@(1),@(12),@(1)];
        result = [db executeUpdate:tagInsertString,@(1),@(12),@(1)];
    }];
    
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *result = [db executeQuery:@"SELECT * FROM way_node"];
        
        int count = 0;
        
        while ([result next]){
            NSDictionary *resultDictionary = [result resultDictionary];
            XCTAssertTrue([resultDictionary[@"way_id"] intValue] == 1);
            XCTAssertTrue([resultDictionary[@"node_id"] intValue] == 11+count);
            XCTAssertTrue([resultDictionary[@"local_order"] intValue] == count);
            count++;
        }
        
        XCTAssertTrue(count == 2, @"Too many");
    }];
}

@end

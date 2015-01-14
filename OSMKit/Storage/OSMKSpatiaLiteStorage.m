//
//  OSMKSpatialLiteStorage.m
//  OSMKit
//
//  Created by David Chiles on 4/11/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKSpatiaLiteStorage.h"
#import "FMDatabaseQueue.h"
#import <SpatialDBKit/SpatialDatabase.h>
#import <SpatialDBKit/SpatialDatabaseQueue.h>

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "OSMKNote.h"
#import "OSMKComment.h"
#import "OSMKUser.h"
#import "OSMKConstants.h"
#import "FMDatabase+OSMKitSpatiaLite.h"
#import "ShapeKitGeometry.h"

@interface OSMKSpatiaLiteStorage ()

@property (nonatomic, strong) SpatialDatabaseQueue *databaseQueue;

@property (nonatomic) dispatch_queue_t storageQueue;

@end

@implementation OSMKSpatiaLiteStorage

- (instancetype)initWithFilePath:(NSString *)filePath
                       overwrite:(BOOL)overwrite
{
    if (self = [self init]) {
        _filePath = filePath;
        self.databaseQueue = [SpatialDatabaseQueue databaseQueueWithPath:self.filePath];
        
        [self setupDatabaseWithOverwrite:overwrite];
    }
    return self;
}

- (void)setupDatabaseWithOverwrite:(BOOL)overwrite
{
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        ////// Remove Tables //////
        
        
        
        //////  Indexes //////
       // sucess = [db executeUpdate:@"CREATE INDEX way_nodes_way_id ON way_nodes ( way_id );"];
        //sucess = [db executeUpdate:@"CREATE INDEX way_nodes_node_id ON way_nodes ( node_id )"];
        
    }];
    
}

#pragma - mark Public Fetching Methods

- (OSMKNode *)nodeWithOsmId:(int64_t)osmId
{
    __block OSMKNode *node = nil;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        node = [db osmk_nodeWithOsmId:osmId];
    }];
    return node;
}

- (void)nodeWithOsmId:(int64_t)osmId completion:(void (^)(OSMKNode *node, NSError *error))completionBlock
{
    dispatch_async(self.storageQueue, ^{
        OSMKNode *node =[self nodeWithOsmId:osmId];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(node,nil);
            });
        }
    });
}

- (OSMKWay *)wayWithOsmId:(int64_t)osmId
{
    __block OSMKWay *way = nil;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        way = [db osmk_wayWithOsmId:osmId];
    }];
    return way;
}

- (void)wayWithOsmId:(int64_t)osmId completion:(void (^)(OSMKWay *way, NSError *error))completionBlock
{
    dispatch_async(self.storageQueue, ^{
        OSMKWay *way =[self wayWithOsmId:osmId];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(way,nil);
            });
        }
    });
}

- (OSMKRelation *)relationWithOsmId:(int64_t)osmId
{
    __block OSMKRelation *relation = nil;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        relation = [db osmk_relationWithOsmId:osmId];
    }];
    return relation;
}

- (void)relationWithOsmId:(int64_t)osmId completion:(void (^)(OSMKRelation *relation, NSError *error))completionBlock
{
    dispatch_async(self.storageQueue, ^{
        OSMKRelation *relation =[self relationWithOsmId:osmId];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(relation,nil);
            });
        }
    });
}

- (void)userWithOsmId:(int64_t)osmId completion:(void (^)(OSMKUser *user, NSError *error))completionBlock
{
    dispatch_async(self.storageQueue, ^{
        __block OSMKUser *user = nil;
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            user = [db osmk_userWithOsmId:osmId];
        }];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(user,nil);
            });
        }
    });
}

- (void)noteWithOsmId:(int64_t)osmId completion:(void (^)(OSMKNote *note, NSError *error))completionBlock
{
    dispatch_async(self.storageQueue, ^{
        __block OSMKNote *note = nil;
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            note = [db osmk_noteWithOsmId:osmId];
        }];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(note,nil);
            });
        }
    });
}

#pragma - mark Class Methods
+ (instancetype)spatiaLiteStorageWithFilePath:(NSString *)filePath overwrite:(BOOL)overwrite
{
    return [[self alloc] initWithFilePath:filePath overwrite:overwrite];
}

@end

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
        BOOL sucess = YES;
        if (overwrite) {
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@",OSMKNodeElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKNodeElementName,OSMKTagElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@",OSMKWayElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKWayElementName,OSMKTagElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKWayElementName,OSMKNodeElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@",OSMKRelationElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKRelationElementName,OSMKTagElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKRelationElementName,OSMKRelationMemberElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@",OSMKNoteElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKNoteElementName,OSMKNoteCommentsElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@",OSMKUserElementName];
            if (sucess) sucess = [db executeUpdateWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKUserElementName,OSMKUserRolesElementName];
        }
        
        
        FMResultSet *resultSet = [db executeQuery:@"SELECT InitSpatialMetaData()"];
        if ([resultSet next]) {
            sucess = [[resultSet objectForColumnName:@"InitSpatialMetaData()"] boolValue];
        }else {
            sucess = NO;
        }
        
        ////// Nodes //////
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (node_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action TEXT, time_stamp TEXT)",OSMKNodeElementName]];
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (node_id INTEGER REFERENCES %@ ( way_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( node_id, key, value ))",OSMKNodeElementName,OSMKTagElementName,OSMKWayNodeElementName]];
        
        resultSet = [db executeQueryWithFormat:[NSString stringWithFormat: @"SELECT AddGeometryColumn('%@', 'geom', 4326, 'POINT', 'XY')",OSMKNodeElementName]];
        if ([resultSet next]) {
            NSArray *values = [[resultSet resultDictionary] allValues];
            sucess = [[values firstObject] boolValue];
        }
        
        ////// Ways //////
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (way_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action INTEGER, time_stamp TEXT)",OSMKWayElementName]];
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (way_id INTEGER REFERENCES %@ ( way_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( way_id, key, value ))",OSMKWayElementName,OSMKTagElementName,OSMKWayElementName]];
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (way_id INTEGER REFERENCES %@ ( way_id ), node_id INTEGER REFERENCES %@ ( id ), local_order INTEGER, UNIQUE ( way_id, local_order ))",OSMKWayElementName,OSMKNodeElementName,OSMKWayElementName,OSMKNodeElementName]];
        
        resultSet = [db executeQueryWithFormat:[NSString stringWithFormat: @"SELECT AddGeometryColumn('%@', 'geom', 4326, 'LINESTRING', 2)",OSMKWayElementName]];
        if ([resultSet next]) {
            NSArray *values = [[resultSet resultDictionary] allValues];
            sucess = [[values firstObject] boolValue];
        }
        
        ////// Relations //////
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (relation_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action INTEGER, time_stamp TEXT)",OSMKRelationElementName]];
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (relation_id INTEGER REFERENCES %@ ( relation_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( relation_id, key, value ))",OSMKRelationElementName,OSMKTagElementName,OSMKRelationElementName]];
        if (sucess) sucess = [db executeUpdate:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (relation_id INTEGER REFERENCES %@ ( relation_id ), type TEXT CHECK ( type IN (\"%@\", \"%@\", \"%@\")),ref INTEGER NOT NULL , role TEXT, local_order INTEGER,UNIQUE (relation_id,ref,local_order) )",OSMKRelationElementName,OSMKRelationMemberElementName,OSMKRelationElementName,OSMKNodeElementName,OSMKWayElementName,OSMKRelationElementName]];
        
        ////// Notes //////
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (note_id INTEGER PRIMARY KEY NOT NULL, open INTEGER, date_created TEXT, date_closed TEXT)",OSMKNoteElementName]];
        
        resultSet = [db executeQueryWithFormat:[NSString stringWithFormat:@"SELECT AddGeometryColumn('%@', 'geom', 4326, 'POINT', 'XY')",OSMKNoteElementName]];
        if ([resultSet next]) {
            NSArray *values = [[resultSet resultDictionary] allValues];
            sucess = [[values firstObject] boolValue];
        }
        
        ////// Comments //////
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (note_id INTEGER REFERENCES %@ ( note_id ), user_id INTEGER,user TEXT, date TEXT, text TEXT, action TEXT, local_order INTEGER)",OSMKNoteElementName,OSMKNoteCommentsElementName,OSMKNoteElementName]];
        
        ////// Users //////
        
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (user_id INTEGER, display_name TEXT, date_created TEXT, image_url TEXT, user_description TEXT, terms_agreed INTEGER, changeset_count INTEGER, trace_count INTEGER,received_blocks INTEGER, active_received_blocks INTEGER, issued_blocks INTEGER, active_issued_blocks INTEGER)",OSMKUserElementName]];
        
        if (sucess) sucess = [db executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (user_id INTEGER REFERENCES %@ (user_id), role TEXT)",OSMKUserElementName,OSMKUserRolesElementName,OSMKUserElementName]];
        
        
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

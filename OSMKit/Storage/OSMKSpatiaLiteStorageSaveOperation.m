//
//  OSMKSpatiaLiteStorageOperation.m
//  OSMKit
//
//  Created by David Chiles on 12/2/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKSpatiaLiteStorageSaveOperation.h"

#import "FMDB.h"

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "OSMKUser.h"
#import "OSMKNote.h"
#import "OSMKComment.h"
#import "ShapeKitGeometry.h"

@interface OSMKSpatiaLiteStorageSaveOperation ()

@property (nonatomic, strong) NSArray *nodes;
@property (nonatomic, strong) NSArray *ways;
@property (nonatomic, strong) NSArray *relations;
@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *notes;

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end

@implementation OSMKSpatiaLiteStorageSaveOperation

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databseQueue
{
    if (self = [self init]) {
        self.databaseQueue = databseQueue;
    }
    return self;
}

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databseQueue
                                nodes:(NSArray *)nodes
                                 ways:(NSArray *)ways
                            relations:(NSArray *)relations
{
    if (self = [self initWithDatabaseQueue:databseQueue]) {
        self.nodes = nodes;
        self.ways = ways;
        self.relations = relations;
    }
    return self;
}

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databseQueue
                                notes:(NSArray *)notes
{
    if (self = [self initWithDatabaseQueue:databseQueue]) {
        self.notes = notes;
    }
    return self;
}

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databseQueue
                                users:(NSArray *)users
{
    if (self = [self initWithDatabaseQueue:databseQueue]) {
        self.users = users;
    }
    return self;
}

- (void)main
{
    dispatch_queue_t queue = self.completionQueue ?: dispatch_get_main_queue();
    
    NSArray *nodes = [self saveNodes:self.nodes];
    NSArray *ways = [self saveWays:self.ways];
    NSArray *relations = [self saveRelations:self.relations];
    
    if (self.elementsCompletionBlock) {
        dispatch_async(queue, ^{
            self.elementsCompletionBlock(nodes,ways,relations);
        });
    }
    
    
    NSArray *notes = [self saveNotes:self.notes];
    
    if (self.notesCompletionBlock) {
        dispatch_async(queue, ^{
            self.notesCompletionBlock(notes);
        });
    }
    
    NSArray *users = [self saveUsers:self.users];
    
    if (self.usersCompletionBlock) {
        dispatch_async(queue, ^{
            self.usersCompletionBlock(users);
        });
    }
    
}

- (NSArray *)saveNodes:(NSArray *)nodes
{
    NSMutableArray *savedNodes = [NSMutableArray new];
    [nodes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[OSMKNode class]]) {
            __block OSMKNode *node = (OSMKNode *)obj;
            __block NSString *geomString = [NSString stringWithFormat:@"GeomFromText('POINT(%f %f)', 4326)",node.latitude,node.longitude];
            __block NSString *updateString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO nodes (node_id,version,changeset,user_id,visible,user,action,time_stamp,geom) VALUES (?,?,?,?,?,?,?,?,%@)",geomString];
            
            [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                BOOL nodeResult = [db executeUpdate:updateString,@(node.osmId),@(node.version),@(node.changeset),@(node.userId),@(node.visible),node.user,node.action,node.timeStamp];
                
                BOOL tagDeleteResult = [db executeUpdateWithFormat:@"DELETE FROM nodes_tags WHERE node_id = %lld",node.osmId];
                
                __block BOOL tagInsertResult = YES;
                [node.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    tagInsertResult = [db executeUpdateWithFormat:@"INSERT INTO nodes_tags (node_id, key, value) VALUES (%lld,%@,%@)",node.osmId,key,obj];
                    if (!tagInsertResult) {
                        *stop = YES;
                    }
                }];
                
                if (nodeResult && tagDeleteResult && tagInsertResult) {
                    [savedNodes addObject:node];
                }
                else {
                    *rollback = YES;
                }
            }];
        }
    }];
    
    return savedNodes;
}

- (NSArray *)saveWays:(NSArray *)ways;
{
    NSMutableArray *savedWays =  [NSMutableArray new];
    [ways enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[OSMKWay class]]) {
            OSMKWay *way = obj;
            
            [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                NSMutableArray *pointStringArray = [NSMutableArray array];
                
                //FIXME check if version is good
                
                //DELETE all old ways_nodes that might be in the database
                BOOL deleteNodesResult = [db executeUpdateWithFormat:@"DELETE FROM ways_nodes WHERE way_id == %lld",way.osmId];
                __block BOOL nodeInsertResult = YES;
                
                [way.nodes enumerateObjectsUsingBlock:^(NSNumber *nodeId, NSUInteger idx, BOOL *stop) {
                    CLLocationCoordinate2D nodeCenter = [self centerOfNode:[nodeId longLongValue] inDatabase:db];
                    if (nodeCenter.latitude != DBL_MAX) {
                        [pointStringArray addObject:[NSString stringWithFormat:@"%f %f",nodeCenter.latitude,nodeCenter.longitude]];
                    }
                    
                    //INSERT all the new way_nodes into the database
                    nodeInsertResult = [db executeUpdateWithFormat:@"INSERT INTO ways_nodes (way_id,node_id,local_order) VALUES (%lld,%lld,%ld)",way.osmId,[nodeId longLongValue],idx];
                    if (!nodeInsertResult) {
                        *stop = YES;
                    }
                    
                }];
                
                NSString *geomString = [NSString stringWithFormat:@"GeomFromText('LINESTRING( %@ )', 4326)",[pointStringArray componentsJoinedByString:@","]];
                
                NSString *updateString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ways (way_id,version,changeset,user_id,visible,user,action,time_stamp,geom) VALUES (?,?,?,?,?,?,?,?,%@)",geomString];
                
                
                //INSERT Way into database
                BOOL wayResult = [db executeUpdate:updateString,@(way.osmId),@(way.version),@(way.changeset),@(way.userId),@(way.visible),way.user,way.action,way.timeStamp];
                
                //Delete Tags
                BOOL tagDeleteResult = [db executeUpdateWithFormat:@"DELETE FROM ways_tags WHERE way_id = %lld",way.osmId];
                
                
                //INsert new tags
                __block BOOL tagInsertResult = YES;
                [way.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    tagInsertResult = [db executeUpdateWithFormat:@"INSERT INTO ways_tags (way_id, key, value) VALUES (%lld,%@,%@)",way.osmId,key,obj];
                    if (!tagInsertResult) {
                        *stop = YES;
                    }
                }];

                if (tagDeleteResult && tagInsertResult && wayResult && nodeInsertResult && deleteNodesResult) {
                    [savedWays addObject:way];
                }
                else {
                    *rollback = YES;
                }
            }];
            
        }
    }];
    
    if (![savedWays count]) {
        savedWays = nil;
    }
    
    return savedWays;
}

- (NSArray *)saveRelations:(NSArray *)relations
{
    NSMutableArray *savedRelations = [NSMutableArray new];
    [relations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[OSMKRelation class]]) {
            OSMKRelation *relation = (OSMKRelation *)obj;
            
            [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                BOOL insertRelationResult = [db executeUpdateWithFormat:@"INSERT OR REPLACE INTO relations (relation_id,version,changeset,user_id,visible,user,action,time_stamp) VALUES (%lld,%d,%lld,%lld,%d,%@,%ld,%@)",relation.osmId,relation.version,relation.changeset,relation.userId,relation.visible,relation.user,relation.action,relation.timeStamp];
                
                BOOL deleteRelationMembersResults = [db executeUpdateWithFormat:@"DELETE FROM relations_members WHERE relation_id = %lld",relation.osmId];
                __block BOOL insertMembersResult = YES;
                [relation.members enumerateObjectsUsingBlock:^(OSMKRelationMember *member, NSUInteger idx, BOOL *stop) {
                    
                    insertMembersResult = [db executeUpdateWithFormat:@"INSERT INTO relations_members (relation_id,type,ref,role,local_order) VALUES (%lld,%@,%lld,%@,%ld)",relation.osmId,[OSMKObject stringForType:member.type],member.ref,member.role,idx];
                    
                    if (!insertMembersResult) {
                        *stop = YES;
                    }
                }];
                
                BOOL deleteTagsResult = [db executeUpdateWithFormat:@"DELETE FROM relations_tags WHERE relation_id = %lld",relation.osmId];
                
                __block BOOL tagInsertResult = YES;
                [relation.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    tagInsertResult = [db executeUpdateWithFormat:@"INSERT INTO relations_tags (relation_id, key, value) VALUES (%lld,%@,%@)",relation.osmId,key,obj];
                    if (!tagInsertResult) {
                        *stop = YES;
                    }
                }];
                
                if (deleteTagsResult && tagInsertResult && insertMembersResult && insertRelationResult &&deleteRelationMembersResults) {
                    [savedRelations addObject:relation];
                }
                else {
                    *rollback = YES;
                }
            }];
        }
    }];
    
    if (![savedRelations count]) {
        savedRelations = nil;
    }
    
    return savedRelations;
}

- (NSArray *)saveNotes:(NSArray *)notes
{
    NSMutableArray *savedNotes = [NSMutableArray new];
    
    return savedNotes;
}

- (NSArray *)saveUsers:(NSArray *)users
{
    NSMutableArray *savedUsers = [NSMutableArray new];
    
    return savedUsers;
}

- (CLLocationCoordinate2D)centerOfNode:(int64_t)nodeId inDatabase:(FMDatabase *)database
{
    FMResultSet *resultSet = [database executeQueryWithFormat:@"SELECT geom FROM nodes WHERE node_id = %lld LIMIT 1",nodeId];
    
    while (resultSet.next) {
        ShapeKitPoint *point = [resultSet objectForColumnName:@"geom"];
        return point.coordinate;
    }
    return CLLocationCoordinate2DMake(DBL_MAX, DBL_MAX);
}

@end

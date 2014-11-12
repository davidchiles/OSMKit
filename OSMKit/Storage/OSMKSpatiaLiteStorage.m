//
//  OSMKSpatialLiteStorage.m
//  OSMKit
//
//  Created by David Chiles on 4/11/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKSpatiaLiteStorage.h"
#import "FMDatabaseQueue.h"
#import "SpatialDatabase.h"

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "OSMKNote.h"
#import "OSMKComment.h"
#import "OSMKUser.h"
#import "OSMKXMLParser.h"

#import "ShapeKitGeometry.h"

static int bufferMaxLength = 1000;

@interface OSMKSpatiaLiteStorage ()

@property (nonatomic, strong) NSMutableArray *elementBuffer;


@property (nonatomic) BOOL hasImportedFirstObject;

@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end

@implementation OSMKSpatiaLiteStorage

- (id)init
{
    if (self = [super init]) {
        self.elementBuffer = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithdatabaseFilePath:(NSString *)filePath delegate:(id<OSMKStorageDelegateProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue overwrite:(BOOL)overwrite
{
    if (self = [super initWithdatabaseFilePath:filePath delegate:delegate delegateQueue:delegateQueue]) {
        self.database = [[SpatialDatabase alloc] initWithPath:self.filePath];
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.filePath];
        
        [self setupDatabaseWithOverwrite:overwrite];
        
    }
    return self;
}

- (instancetype)initWithdatabaseFilePath:(NSString *)filePath delegate:(id<OSMKStorageDelegateProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    return [self initWithdatabaseFilePath:filePath delegate:delegate delegateQueue:delegateQueue overwrite:YES];
}

- (void)importXMLData:(NSData *)data
{
    [super importXMLData:data];
}

- (void)setupDatabaseWithOverwrite:(BOOL)overwrite
{
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *resultSet = [db executeQuery:@"SELECT InitSpatialMetaData()"];
        while (resultSet.next) {
            NSLog(@"%@",[resultSet resultDictionary]);
        }
        
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
        
        
        ////// Nodes //////
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (node_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action TEXT, time_stamp TEXT)",OSMKNodeElementName];
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (node_id INTEGER REFERENCES %@ ( way_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( node_id, key, value ))",OSMKNodeElementName,OSMKTagElementName,OSMKWayNodeElementName];
        
        resultSet = [db executeQueryWithFormat:@"SELECT AddGeometryColumn('%@', 'geom', 4326, 'POINT', 'XY')",OSMKNodeElementName];
        while (resultSet.next) {
            NSLog(@"%@",[resultSet resultDictionary]);
        }
        
        ////// Ways //////
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (way_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action INTEGER, time_stamp TEXT)",OSMKWayElementName];
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (way_id INTEGER REFERENCES %@ ( way_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( way_id, key, value ))",OSMKWayElementName,OSMKTagElementName,OSMKWayElementName];
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (way_id INTEGER REFERENCES %@ ( way_id ), node_id INTEGER REFERENCES %@ ( id ), local_order INTEGER, UNIQUE ( way_id, local_order, node_id ))",OSMKWayElementName,OSMKNodeElementName,OSMKWayElementName,OSMKNodeElementName];
        
        resultSet = [db executeQueryWithFormat:@"SELECT AddGeometryColumn('%@', 'geom', 4326, 'LINESTRING', 2)",OSMKWayElementName];
        while (resultSet.next) {
            NSLog(@"%@",[resultSet resultDictionary]);
        }
        
        ////// Relations //////
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (relation_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action INTEGER, time_stamp TEXT)",OSMKRelationElementName];
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (relation_id INTEGER REFERENCES %@ ( relation_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( relation_id, key, value ))",OSMKRelationElementName,OSMKTagElementName,OSMKRelationElementName];
        if (sucess) sucess = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS %@_%@ (relation_id INTEGER REFERENCES %@ ( relation_id ), type TEXT CHECK ( type IN (\"%@\", \"%@\", \"%@\")),ref INTEGER NOT NULL , role TEXT, local_order INTEGER,UNIQUE (relation_id,ref,local_order) )",OSMKRelationElementName,OSMKRelationMemberElementName,OSMKRelationElementName,OSMKNodeElementName,OSMKWayElementName,OSMKRelationElementName];
        
        ////// Notes //////
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (note_id INTEGER PRIMARY KEY NOT NULL, open INTEGER, date_created TEXT, date_closed TEXT)",OSMKNoteCommentsElementName];
        
        resultSet = [db executeQueryWithFormat:@"SELECT AddGeometryColumn('%@', 'geom', 4326, 'POINT', 'XY')",OSMKNoteCommentsElementName];
        while (resultSet.next) {
            NSLog(@"%@",[resultSet resultDictionary]);
        }
        
        ////// Comments //////
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (note_id INTEGER REFERENCES %@ ( note_id ), user_id INTEGER,user TEXT, date TEXT, text TEXT, action TEXT, local_order INTEGER)",OSMKNoteElementName,OSMKNoteCommentsElementName,OSMKNoteElementName];
        
        ////// Users //////
        
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (user_id INTEGER, display_name TEXT, date_created TEXT, image_url TEXT, user_description TEXT, terms_agreed INTEGER, changeset_count INTEGER, trace_count INTEGER,received_blocks INTEGER, active_received_blocks INTEGER, issued_blocks INTEGER, active_issued_blocks INTEGER)",OSMKUserElementName];
        
        if (sucess) sucess = [db executeUpdateWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (user_id INTEGER REFERENCES %@ (user_id), role TEXT)",OSMKUserElementName,OSMKUserRolesElementName,OSMKUserElementName];
        
        
        //////  Indexes //////
       // sucess = [db executeUpdate:@"CREATE INDEX way_nodes_way_id ON way_nodes ( way_id );"];
        //sucess = [db executeUpdate:@"CREATE INDEX way_nodes_node_id ON way_nodes ( node_id )"];
        
    }];
    
}


- (void)addElementToBuffer:(id)object
{
    dispatch_async(self.storageQueue, ^{
        if (object) {
            [self.elementBuffer addObject:object];
            if ([self.elementBuffer count] > bufferMaxLength) {
                [self saveElements:self.elementBuffer];
                [self.elementBuffer removeAllObjects];
            }
        }
    });
}

- (void)finalFlushElementBuffer
{
    dispatch_async(self.storageQueue, ^{
        [self saveElements:self.elementBuffer];
        [self.elementBuffer removeAllObjects];
        [self didFinishImporting];
    });
}



#pragma - mark Saving Methods

- (void)saveElements:(NSArray *)elements
{
    if ([elements count]) {
        
        NSMutableArray *savedNodes = [NSMutableArray array];
        NSMutableArray *savedWays = [NSMutableArray array];
        NSMutableArray *savedRelations = [NSMutableArray array];
        NSMutableArray *savedUsers = [NSMutableArray array];
        NSMutableArray *savedNotes = [NSMutableArray array];
        
        
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [elements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj isKindOfClass:[OSMKNode class]]) {
                    if ([self saveNode:obj inDatabse:db]) {
                        [savedNodes addObject:obj];
                    }
                }
                else if ([obj isKindOfClass:[OSMKWay class]]) {
                    if ([self saveWay:obj inDatabase:db]) {
                        [savedWays addObject:obj];
                    }
                }
                else if ([obj isKindOfClass:[OSMKRelation class]]) {
                    if ([self saveRelation:obj inDatabase:db]) {
                        [savedRelations addObject:obj];
                    }
                }
                else if ([obj isKindOfClass:[OSMKNote class]]) {
                    if([self saveNote:obj inDatabase:db]) {
                        [savedNotes addObject:obj];
                    }
                }
                else if ([obj isKindOfClass:[OSMKUser class]]) {
                    if ([self saveUser:obj inDatabase:db]) {
                        [savedUsers addObject:obj];
                    }
                }
                
            }];
        }];
        
        if ([savedNodes count]) {
            [self didSaveNodes:savedNodes];
        }
        
        if ([savedWays count]) {
            [self didSaveWays:savedWays];
        }
        
        if ([savedRelations count]) {
            [self didSaveRelations:savedRelations];
        }
        
        if ([savedUsers count]) {
            [self didSaveUsers:savedUsers];
        }
        
        if ([savedNotes count]) {
            [self didSaveNotes:savedNotes];
        }
    }
}

- (void)didStartImporting
{
    if ([self.delegate respondsToSelector:@selector(storageDidStartImporting:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate storageDidStartImporting:self];
        });
    }
}

- (void)didFinishImporting
{
    if ([self.delegate respondsToSelector:@selector(storageDidFinishImporting:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate storageDidFinishImporting:self];
        });
    }
}

- (void)didSaveNodes:(NSArray *)array
{
    if ([self.delegate respondsToSelector:@selector(storage:didSaveNodes:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate storage:self didSaveNodes:array];
        });
    }
}

- (void)didSaveWays:(NSArray *)array
{
    if ([self.delegate respondsToSelector:@selector(storage:didSaveWays:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate storage:self didSaveWays:array];
        });
    }
}

- (void)didSaveRelations:(NSArray *)array
{
    if ([self.delegate respondsToSelector:@selector(storage:didSaveRelations:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate storage:self didSaveRelations:array];
        });
    }
}

- (void)didSaveNotes:(NSArray *)array
{
    if ([self.delegate respondsToSelector:@selector(storage:didSaveNotes:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate storage:self didSaveNotes:array];
        });
    }
}

- (void)didSaveUsers:(NSArray *)array
{
    if ([self.delegate respondsToSelector:@selector(storage:didSaveUsers:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate storage:self didSaveUsers:array];
        });
    }
}

- (BOOL)saveNode:(OSMKNode *)node inDatabse:(FMDatabase *)database
{
    BOOL result = NO;
    if (node) {
        NSString *geomString = [NSString stringWithFormat:@"GeomFromText('POINT(%f %f)', 4326)",node.latitude,node.longitude];
        NSString *updateString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO nodes (node_id,version,changeset,user_id,visible,user,action,time_stamp,geom) VALUES (?,?,?,?,?,?,?,?,%@)",geomString];
        BOOL nodeResult = [database executeUpdate:updateString,@(node.osmId),@(node.version),@(node.changeset),@(node.userId),@(node.visible),node.user,node.action,node.timeStamp];
        
        BOOL tagDeleteResult = [database executeUpdateWithFormat:@"DELETE FROM nodes_tags WHERE node_id = %lld",node.osmId];
        
        __block BOOL tagInsertResult = YES;
        [node.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            tagInsertResult = [database executeUpdateWithFormat:@"INSERT INTO nodes_tags (node_id, key, value) VALUES (%lld,%@,%@)",node.osmId,key,obj];
            if (!tagInsertResult) {
                *stop = YES;
            }
        }];
        
        result = nodeResult && tagDeleteResult && tagInsertResult;
    }
    
    return result;
}

- (BOOL)saveWay:(OSMKWay *)way inDatabase:(FMDatabase *)database
{
    BOOL result = NO;
    if (way) {
        
        NSMutableArray *pointStringArray = [NSMutableArray array];
        
        BOOL deleteNodesResult = [database executeUpdateWithFormat:@"DELETE FROM ways_nodes WHERE way_id == %lld",way.osmId];
        __block BOOL nodeInsertResult = YES;
        
        [way.nodes enumerateObjectsUsingBlock:^(NSNumber *nodeId, NSUInteger idx, BOOL *stop) {
            CLLocationCoordinate2D nodeCenter = [self centerOfNode:[nodeId longLongValue] inDatabase:database];
            if (nodeCenter.latitude != DBL_MAX) {
                [pointStringArray addObject:[NSString stringWithFormat:@"%f %f",nodeCenter.latitude,nodeCenter.longitude]];
            }
            

            nodeInsertResult = [database executeUpdateWithFormat:@"INSERT INTO ways_nodes (way_id,node_id,local_order) VALUES (%lld,%lld,%d)",way.osmId,[nodeId longLongValue],idx];
            if (!nodeInsertResult) {
                *stop = YES;
            }
            
        }];
        
        if (!nodeInsertResult || !deleteNodesResult) {
            return NO;
        }
        
        NSString *geomString = [NSString stringWithFormat:@"GeomFromText('LINESTRING( %@ )', 4326)",[pointStringArray componentsJoinedByString:@","]];
        
        NSString *updateString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO ways (way_id,version,changeset,user_id,visible,user,action,time_stamp,geom) VALUES (?,?,?,?,?,?,?,?,%@)",geomString];
        
        
         BOOL wayResult = [database executeUpdate:updateString,@(way.osmId),@(way.version),@(way.changeset),@(way.userId),@(way.visible),way.user,way.action,way.timeStamp];
        
        BOOL tagDeleteResult = [database executeUpdateWithFormat:@"DELETE FROM ways_tags WHERE way_id = %lld",way.osmId];
        
        __block BOOL tagInsertResult = YES;
        [way.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            tagInsertResult = [database executeUpdateWithFormat:@"INSERT INTO ways_tags (way_id, key, value) VALUES (%lld,%@,%@)",way.osmId,key,obj];
            if (!tagInsertResult) {
                *stop = YES;
            }
        }];
        
        
        result = tagDeleteResult && tagInsertResult && wayResult;
    }
    return result;
}

- (BOOL)saveRelation:(OSMKRelation *)relation inDatabase:(FMDatabase *)database
{
    BOOL result = NO;
    
    if (relation) {
        
        
        BOOL insertRelationResult = [database executeUpdateWithFormat:@"INSERT OR REPLACE INTO relations (relation_id,version,changeset,user_id,visible,user,action,time_stamp) VALUES (%lld,%d,%lld,%lld,%d,%@,%d,%@)",relation.osmId,relation.version,relation.changeset,relation.userId,relation.visible,relation.user,relation.action,relation.timeStamp];
        if (!insertRelationResult) {
            return NO;
        }
        
        BOOL deleteRelationMembersResults = [database executeUpdateWithFormat:@"DELETE FROM relations_members WHERE relation_id = %lld",relation.osmId];
        __block BOOL insertMembersResult = YES;
        [relation.members enumerateObjectsUsingBlock:^(OSMKRelationMember *member, NSUInteger idx, BOOL *stop) {
            
            insertMembersResult = [database executeUpdateWithFormat:@"INSERT INTO relations_members (relation_id,type,ref,role,local_order) VALUES (%lld,%@,%lld,%@,%d)",relation.osmId,[OSMKObject stringForType:member.type],member.ref,member.role,idx];
            
            if (!insertMembersResult) {
                *stop = YES;
            }
        }];
        
        if (!deleteRelationMembersResults || !insertMembersResult) {
            return NO;
        }
        
        
        BOOL deleteTagsResult = [database executeUpdateWithFormat:@"DELETE FROM relations_tags WHERE relation_id = %lld",relation.osmId];
        
        __block BOOL tagInsertResult = YES;
        [relation.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            tagInsertResult = [database executeUpdateWithFormat:@"INSERT INTO relations_tags (relation_id, key, value) VALUES (%lld,%@,%@)",relation.osmId,key,obj];
            if (!tagInsertResult) {
                *stop = YES;
            }
        }];
        
        result = deleteTagsResult && tagInsertResult;
    }
    
    
    return result;
}

- (BOOL)saveNote:(OSMKNote *)note inDatabase:(FMDatabase *)database
{
    BOOL result = NO;
    
    if (note) {
        NSString *geomString = [NSString stringWithFormat:@"GeomFromText('POINT(%f %f)', 4326)",note.latitude, note.longitude];
        NSString *updateString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO notes (note_id,open,date_created,date_closed,geom) VALUES (?,?,?,?,%@)",geomString];
        BOOL noteResult = [database executeUpdate:updateString,@(note.osmId),@(note.isOpen),note.dateCreated,note.dateClosed];
        
        BOOL deleteCommentsResult = [database executeUpdateWithFormat:@"DELETE FROM notes_comments WHERE note_id = %lld",note.osmId];
        
        __block BOOL insertCommentsReults = YES;
        [note.commentsArray enumerateObjectsUsingBlock:^(OSMKComment *comment, NSUInteger idx, BOOL *stop) {
            
            insertCommentsReults = [database executeUpdateWithFormat:@"INSERT INTO notes_comments (note_id,user_id,user,date,text,action,local_order) VALUES (%lld,%lld,%@,%@,%@,%@,%d)",note.osmId,comment.userId,comment.user,comment.date,comment.text,comment.action,idx];
            
            if (!insertCommentsReults) {
                *stop = YES;
            }
            
        }];
        
        result = noteResult && deleteCommentsResult && insertCommentsReults;
    }
    
    
    return result;
}

- (BOOL)saveUser:(OSMKUser *)user inDatabase:(FMDatabase *)database
{
    BOOL result = NO;
    if (user) {
        BOOL insertResult = [database executeUpdateWithFormat:@"INSERT OR REPLACE INTO users (user_id,display_name,date_created,image_url,user_description,terms_agreed,changeset_count,trace_count,received_blocks,active_received_blocks,issued_blocks,active_issued_blocks) VALUES (%lld,%@,%@,%@,%@,%d,%d,%d,%d,%d,%d,%d)",user.osmId,user.displayName,user.dateCreated,user.imageUrl,user.userDescription,user.termsAgreed,user.changesetCount,user.traceCount,user.receivedBlocks,user.activeReceivedBlocks,user.issuedBlocks,user.activeIssuedBlocks];
        
        BOOL deleteResult = [database executeUpdateWithFormat:@"DELETE FROM users_roles WHERE user_id = %lld",user.osmId];
        
        
        __block BOOL updateRoles = YES;
        [user.roles enumerateObjectsUsingBlock:^(NSString *role, BOOL *stop) {
            updateRoles = [database executeUpdateWithFormat:@"INSERT INTO users_roles (user_id,role) VALUES (%lld,%@)",user.osmId,role];
            
            if (!updateRoles) {
                *stop = YES;
            }
            
            
        }];
        
        result = insertResult && deleteResult && updateRoles;
    }
    
    return result;
}

#pragma - mark Fetching Methods

- (CLLocationCoordinate2D)centerOfNode:(int64_t)nodeId inDatabase:(FMDatabase *)database
{
    FMResultSet *resultSet = [database executeQueryWithFormat:@"SELECT geom FROM nodes WHERE node_id = %lld LIMIT 1",nodeId];
    
    while (resultSet.next) {
        ShapeKitPoint *point = [resultSet objectForColumnName:@"geom"];
        return point.coordinate;
    }
    return CLLocationCoordinate2DMake(DBL_MAX, DBL_MAX);
}

- (OSMKNode *)nodeWithOsmId:(int64_t)nodeId inDatabase:(FMDatabase *)database
{
    OSMKNode *node = [self elementForType:OSMKElementTypeNode elementId:nodeId inDatabase:database];
    if (node) {
        node.tags = [self tagsForElementType:OSMKElementTypeNode elementId:node.osmId inDatabase:database];
    }
    
    return node;
}

- (OSMKWay *)wayWithOsmId:(int64_t)osmId inDatabase:(FMDatabase *)database
{
    OSMKWay *way = [self elementForType:OSMKElementTypeWay elementId:osmId inDatabase:database];
    if (way) {
        way.tags = [self tagsForElementType:OSMKElementTypeWay elementId:osmId inDatabase:database];
        
        FMResultSet *resultSet = [database executeQueryWithFormat:@"SELECT * FROM ways_nodes WHERE way_id = %lld ORDER BY local_order",osmId];
        
        NSMutableArray *nodeIds = [NSMutableArray array];
        while ([resultSet next]) {
            int64_t nodeId = [resultSet longLongIntForColumn:@"node_id"];
            if (nodeId) {
                [nodeIds addObject:@(nodeId)];
            }
        }
        
        if ([nodeIds count]) {
            way.nodes = [nodeIds copy];
        }
    }
    return way;
}

- (OSMKRelation *)relationWithOsmId:(int64_t)osmId inDatabase:(FMDatabase *)database
{
    OSMKRelation *relation = [self elementForType:OSMKElementTypeRelation elementId:osmId inDatabase:database];
    if (relation) {
        relation.tags = [self tagsForElementType:OSMKElementTypeRelation elementId:osmId inDatabase:database];
        
        FMResultSet *resultSet = [database executeQueryWithFormat:@"SELECT * FROM relations_members WHERE relation_id = %lld ORDER BY local_order",osmId];
        
        NSMutableArray *membersMutable = [NSMutableArray array];
        while ([resultSet next]) {
            OSMKRelationMember *relationMember = [[OSMKRelationMember alloc] initWithAttributesDictionary:[resultSet resultDictionary]];
            
            if (relationMember) {
                [membersMutable addObject:relationMember];
            }
        }
        relation.members = [membersMutable copy];
    }
    return relation;
}

- (id)elementForType:(OSMKElementType)elementType elementId:(int64_t)elementId inDatabase:(FMDatabase *)database
{
    NSString *tableName = [NSString stringWithFormat:@"%@s",[OSMKObject stringForType:elementType]];
    NSString *idColumnName = [NSString stringWithFormat:@"%@_id",[OSMKObject stringForType:elementType]];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %lld LIMIT 1",tableName,idColumnName,elementId];
    
    FMResultSet *resultSet = [database executeQuery:query];
    OSMKObject *object = nil;
    if (resultSet.next) {
        object = (OSMKObject *)[OSMKObject objectForType:elementType elementId:elementId];
 
        object.action = [resultSet intForColumn:@"action"];
        object.changeset = [resultSet longForColumn:@"changeset"];
        object.timeStamp = [resultSet dateForColumn:@"time_stamp"];
        object.user = [resultSet stringForColumn:@"user"];
        object.version = [resultSet intForColumn:@"version"];
        object.visible = [resultSet boolForColumn:@"visible"];
        object.userId = [resultSet longLongIntForColumn:@"user_id"];
        if (elementType == OSMKElementTypeNode) {
            ShapeKitPoint *point = [resultSet objectForColumnName:@"geom"];
            ((OSMKNode *)object).coordinate = point.coordinate;
        }
        
    }
    
    return object;
}

- (NSDictionary *)tagsForElementType:(OSMKElementType)elementType elementId:(int64_t)elementId inDatabase:(FMDatabase *)database
{
    NSString *tableName = [NSString stringWithFormat:@"%@s_tags",[OSMKObject stringForType:elementType]];
    NSString *idColumnName = [NSString stringWithFormat:@"%@_id",[OSMKObject stringForType:elementType]];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %lld",tableName,idColumnName,elementId];
    FMResultSet *resultSet = [database executeQuery:query];
    NSMutableDictionary *mutableTags = [NSMutableDictionary dictionary];
    while (resultSet.next) {
        NSString *key = [resultSet stringForColumn:@"key"];
        NSString *value = [resultSet stringForColumn:@"value"];
        if (key && value) {
            mutableTags[key] = value;
        }
    }
    
    if ([mutableTags count]) {
        return [mutableTags copy];
    }
    return nil;
}

#pragma - mark Public Fetching Methods

- (OSMKNode *)nodeWithOsmId:(int64_t)osmId
{
    __block OSMKNode *node = nil;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        node = [self nodeWithOsmId:osmId inDatabase:db];
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
        way = [self wayWithOsmId:osmId inDatabase:db];
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
        relation = [self relationWithOsmId:osmId inDatabase:db];
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

- (OSMKUser *)userWithOsmId:(int64_t)osmId
{
    __block OSMKUser *user = nil;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *resultsSet = [db executeQueryWithFormat:@"SELECT * FROM users WHERE user_id = %lld LIMIT 1",osmId];
        if ([resultsSet next]) {
            user = [[OSMKUser alloc] initWIthOsmId:[resultsSet longLongIntForColumn:@"user_id"]];
            user.displayName = [resultsSet stringForColumn:@"display_name"];
            user.dateCreated = [resultsSet dateForColumn:@"date_created"];
            user.imageUrl = [NSURL URLWithString:[resultsSet stringForColumn:@"image_url"]];
            user.userDescription = [resultsSet stringForColumn:@"user_description"];
            user.termsAgreed = [resultsSet boolForColumn:@"terms_agreed"];
            user.changesetCount = [resultsSet intForColumn:@"changeset_count"];
            user.traceCount = [resultsSet intForColumn:@"trace_count"];
            user.receivedBlocks = [resultsSet intForColumn:@"received_blocks"];
            user.activeReceivedBlocks = [resultsSet intForColumn:@"active_received_blocks"];
            user.issuedBlocks = [resultsSet intForColumn:@"issued_blocks"];
            user.activeReceivedBlocks = [resultsSet intForColumn:@"active_issued_blocks"];
        }
        
        if (user) {
            FMResultSet *rolesResultSet = [db executeQueryWithFormat:@"SELECT * FROM users_roles WHERE user_id = %lld",osmId];
            
            NSMutableSet *roleMutableSet = [NSMutableSet set];
            while ([rolesResultSet next]) {
                NSString *role = [rolesResultSet stringForColumn:@"role"];
                if ([role length]) {
                    [roleMutableSet addObject:role];
                }
            }
            user.roles = [roleMutableSet copy];
        }
        
        
    }];
    return user;
}

- (void)userWithOsmId:(int64_t)osmId completion:(void (^)(OSMKUser *user, NSError *error))completionBlock
{
    dispatch_async(self.storageQueue, ^{
        OSMKUser *user =[self userWithOsmId:osmId];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(user,nil);
            });
        }
    });
}

- (OSMKNote *)noteWithOsmId:(int64_t)osmId
{
    __block OSMKNote *note = nil;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *resultSet = [db executeQueryWithFormat:@"SELECT * from notes where note_id = %lld LIMIT 1",osmId];
        
        if ([resultSet next]) {
            note = [[OSMKNote alloc] init];
            note.osmId = osmId;
            note.isOpen = [resultSet boolForColumn:@"open"];
            note.dateCreated = [resultSet dateForColumn:@"date_created"];
            note.dateClosed = [resultSet dateForColumn:@"date_closed"];
            ShapeKitPoint *point = [resultSet objectForColumnName:@"geom"];
            note.coordinate = point.coordinate;
        }
        
        if (note) {
             resultSet = [db executeQueryWithFormat:@"SELECT * FROM notes_comments WHERE note_id = %lld ORDER BY local_order",osmId];
            
            NSMutableArray *commentsMutableArray = [NSMutableArray array];
            while ([resultSet next]) {
                OSMKComment *comment = [[OSMKComment alloc] init];
                comment.noteId = osmId;
                comment.userId = [resultSet longLongIntForColumn:@"user_id"];
                comment.user = [resultSet stringForColumn:@"user"];
                comment.date = [resultSet dateForColumn:@"date"];
                comment.text = [resultSet stringForColumn:@"text"];
                comment.action = [resultSet stringForColumn:@"action"];
                [commentsMutableArray addObject:comment];
            }
            
            if ([commentsMutableArray count]) {
                note.commentsArray = [commentsMutableArray copy];
            }
            
            
        }
       
        
    }];
    return note;
}

- (void)noteWithOsmId:(int64_t)osmId completion:(void (^)(OSMKNote *note, NSError *error))completionBlock
{
    dispatch_async(self.storageQueue, ^{
        OSMKNote *note =[self noteWithOsmId:osmId];
        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(note,nil);
            });
        }
    });
}


#pragma - mark OSMKStorageDelegateProtocol

- (void)parserDidStart:(OSMKParser *)parser
{
    [self didStartImporting];
}
- (void)parser:(OSMKParser *)parser didFindNode:(OSMKNode *)node
{
    [self addElementToBuffer:node];
}
- (void)parser:(OSMKParser *)parser didFindWay:(OSMKWay *)way
{
    [self addElementToBuffer:way];
}
- (void)parser:(OSMKParser *)parser didFindRelation:(OSMKRelation *)relation
{
    [self addElementToBuffer:relation];
}
- (void)parser:(OSMKParser *)parser didFindNote:(OSMKNote *)note
{
    [self addElementToBuffer:note];
}
- (void)parser:(OSMKParser *)parser didFindUser:(OSMKUser *)user
{
    [self addElementToBuffer:user];
}

- (void)parserDidFinish:(OSMKParser *)parser
{
    [self finalFlushElementBuffer];
}

#pragma - mark Class Methods

+ (NSString *)tableNameForObject:(id)object
{
    if ([object isKindOfClass:[OSMKNode class]]) {
        return OSMKNodeElementName;
    }
    else if ([object isKindOfClass:[OSMKWay class]]) {
        return OSMKWayElementName;
    }
    else if ([object isKindOfClass:[OSMKWay class]]) {
        return OSMKRelationElementName;
    }
    else if ([object isKindOfClass:[OSMKUser class]]) {
        return OSMKUserElementName;
    }
    else if ([object isKindOfClass:[OSMKNote class]]) {
        return OSMKNoteElementName;
    }
    
    return nil;
}

@end

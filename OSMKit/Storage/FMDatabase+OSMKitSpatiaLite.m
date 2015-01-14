//
//  FMDatabase+OSMKit.m
//  Pods
//
//  Created by David Chiles on 12/15/14.
//
//

#import "FMDatabase+OSMKitSpatiaLite.h"

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKUser.h"
#import "OSMKNote.h"
#import "OSMKConstants.h"
#import "ShapeKit.h"
#import "OSMKRelationMember.h"
#import "OSMKComment.h"

@implementation FMDatabase (OSMKitSpatiaLite)

#pragma - mark Setup Method

- (BOOL)osmk_setupDatabaseWithOverwrite:(BOOL)overwrite
{
    BOOL sucess = YES;
    if (overwrite) {
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@",OSMKNodeElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKNodeElementName,OSMKTagElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@",OSMKWayElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKWayElementName,OSMKTagElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKWayElementName,OSMKNodeElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@",OSMKRelationElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKRelationElementName,OSMKTagElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKRelationElementName,OSMKRelationMemberElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@",OSMKNoteElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKNoteElementName,OSMKNoteCommentsElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@",OSMKUserElementName]];
        if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat:@"DROP TABLE IF EXISTS %@_%@",OSMKUserElementName,OSMKUserRolesElementName]];
    }
    
    FMResultSet *resultSet = [self executeQuery:@"SELECT InitSpatialMetaData();"];
    if ([resultSet next]) {
        NSLog(@"%@",[resultSet resultDictionary]);
    }
    
    ////// Nodes //////
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (node_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action TEXT, time_stamp TEXT)",OSMKNodeElementName]];
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (node_id INTEGER REFERENCES %@ ( way_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( node_id, key, value ))",OSMKNodeElementName,OSMKTagElementName,OSMKWayNodeElementName]];
    
    resultSet = [self executeQueryWithFormat:[NSString stringWithFormat: @"SELECT AddGeometryColumn('%@', 'geom', 4326, 'POINT', 'XY')",OSMKNodeElementName]];
    if ([resultSet next]) {
        NSArray *values = [[resultSet resultDictionary] allValues];
        //sucess = [[values firstObject] boolValue];
    }
    
    ////// Ways //////
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (way_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action INTEGER, time_stamp TEXT)",OSMKWayElementName]];
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (way_id INTEGER REFERENCES %@ ( way_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( way_id, key, value ))",OSMKWayElementName,OSMKTagElementName,OSMKWayElementName]];
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (way_id INTEGER REFERENCES %@ ( way_id ), node_id INTEGER REFERENCES %@ ( id ), local_order INTEGER, UNIQUE ( way_id, local_order ))",OSMKWayElementName,OSMKNodeElementName,OSMKWayElementName,OSMKNodeElementName]];
    
    resultSet = [self executeQueryWithFormat:[NSString stringWithFormat: @"SELECT AddGeometryColumn('%@', 'geom', 4326, 'LINESTRING', 2)",OSMKWayElementName]];
    if ([resultSet next]) {
        NSArray *values = [[resultSet resultDictionary] allValues];
        //sucess = [[values firstObject] boolValue];
    }
    
    ////// Relations //////
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (relation_id INTEGER PRIMARY KEY NOT NULL,version INTEGER ,changeset INTEGER, user_id INTEGER, visible INTEGER,user TEXT,action INTEGER, time_stamp TEXT)",OSMKRelationElementName]];
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@_%@ (relation_id INTEGER REFERENCES %@ ( relation_id ), key TEXT NOT NULL,value TEXT NOT NULL, UNIQUE ( relation_id, key, value ))",OSMKRelationElementName,OSMKTagElementName,OSMKRelationElementName]];
    if (sucess) sucess = [self executeUpdate:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (relation_id INTEGER REFERENCES %@ ( relation_id ), type TEXT CHECK ( type IN (\"%@\", \"%@\", \"%@\")),ref INTEGER NOT NULL , role TEXT, local_order INTEGER,UNIQUE (relation_id,ref,local_order) )",OSMKRelationElementName,OSMKRelationMemberElementName,OSMKRelationElementName,OSMKNodeElementName,OSMKWayElementName,OSMKRelationElementName]];
    
    ////// Notes //////
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (note_id INTEGER PRIMARY KEY NOT NULL, open INTEGER, date_created TEXT, date_closed TEXT)",OSMKNoteElementName]];
    
    resultSet = [self executeQueryWithFormat:[NSString stringWithFormat:@"SELECT AddGeometryColumn('%@', 'geom', 4326, 'POINT', 'XY')",OSMKNoteElementName]];
    if ([resultSet next]) {
        NSArray *values = [[resultSet resultDictionary] allValues];
        sucess = [[values firstObject] boolValue];
    }
    
    ////// Comments //////
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (note_id INTEGER REFERENCES %@ ( note_id ), user_id INTEGER,user TEXT, date TEXT, text TEXT, action TEXT, local_order INTEGER)",OSMKNoteElementName,OSMKNoteCommentsElementName,OSMKNoteElementName]];
    
    ////// Users //////
    
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@ (user_id INTEGER, display_name TEXT, date_created TEXT, image_url TEXT, user_description TEXT, terms_agreed INTEGER, changeset_count INTEGER, trace_count INTEGER,received_blocks INTEGER, active_received_blocks INTEGER, issued_blocks INTEGER, active_issued_blocks INTEGER)",OSMKUserElementName]];
    
    if (sucess) sucess = [self executeUpdateWithFormat:[NSString stringWithFormat: @"CREATE TABLE IF NOT EXISTS %@_%@ (user_id INTEGER REFERENCES %@ (user_id), role TEXT)",OSMKUserElementName,OSMKUserRolesElementName,OSMKUserElementName]];
    
    return sucess;
}

#pragma - mark Saving Methods

- (BOOL)osmk_saveNode:(OSMKNode *)node error:(NSError **)error
{
    BOOL result = NO;
    if ([node isKindOfClass:[OSMKNode class]]) {
        //INSERT or Replace in node table
        __block NSString *geomString = [NSString stringWithFormat:@"GeomFromText('POINT(%f %f)', 4326)",node.latitude,node.longitude];
        __block NSString *updateString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (node_id,version,changeset,user_id,visible,user,action,time_stamp,geom) VALUES (?,?,?,?,?,?,?,?,%@)",[[self class] osmk_tableNameForObject:node],geomString];
        
        BOOL nodeResult = [self executeUpdate:updateString,@(node.osmId),@(node.version),@(node.changeset),@(node.userId),@(node.visible),node.user,@(node.action),node.timeStamp];
        
        //Delete any existing tags
        BOOL tagDeleteResult = [self executeUpdateWithFormat:[NSString stringWithFormat:@"DELETE FROM %@ WHERE node_id = %lld",[[self class] osmk_tagTableNameForObject:node],node.osmId]];
        
        //Insert tags
        __block BOOL tagInsertResult = YES;
        [node.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *tableName = [[self class] osmk_tagTableNameForObject:node];
            NSString *insertString = [NSString stringWithFormat:@"INSERT INTO %@ (node_id, key, value) VALUES (?,?,?)",tableName];
            tagInsertResult = [self executeUpdate:insertString,@(node.osmId),key,obj];
            if (!tagInsertResult) {
                *stop = YES;
            }
        }];
        
        result = nodeResult && tagDeleteResult && tagInsertResult;
        
        if (!result) {
            //FIXME error failed
        }
    }
    return result;
}

- (BOOL)osmk_saveWay:(OSMKWay *)way error:(NSError **)error
{
    if ([way isKindOfClass:[OSMKWay class]]) {
        //FIXME check if version is good
        
        NSMutableArray *pointStringArray = [[NSMutableArray alloc] initWithCapacity:[way.nodes count]];
        
        //DELETE all old ways_nodes that might be in the database
        NSString *deleteString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE way_id == ?",[[self class] osmk_tagTableNameForObject:way]];
        BOOL deleteNodesResult = [self executeUpdate:deleteString,@(way.osmId)];
        __block BOOL nodeInsertResult = YES;
        
        [way.nodes enumerateObjectsUsingBlock:^(NSNumber *nodeId, NSUInteger idx, BOOL *stop) {
            CLLocationCoordinate2D nodeCenter = [self osmk_coordinateOfNodeWithId:[nodeId longLongValue]];
            if (nodeCenter.latitude != DBL_MAX) {
                [pointStringArray addObject:[NSString stringWithFormat:@"%f %f",nodeCenter.latitude,nodeCenter.longitude]];
            }
            
            //INSERT all the new way_nodes into the database
            nodeInsertResult = [self executeUpdate:@"INSERT INTO way_node (way_id,node_id,local_order) VALUES (?,?,?)",@(way.osmId),nodeId,@(idx)];
            if (!nodeInsertResult) {
                *stop = YES;
            }
            
        }];
        
        NSString *geomString = [NSString stringWithFormat:@"GeomFromText('LINESTRING( %@ )', 4326)",[pointStringArray componentsJoinedByString:@","]];
        
        NSString *updateString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (way_id,version,changeset,user_id,visible,user,action,time_stamp,geom) VALUES (?,?,?,?,?,?,?,?,%@)",[[self class] osmk_tableNameForObject:way],geomString];
        
        //INSERT Way into database
        BOOL wayResult = [self executeUpdate:updateString,@(way.osmId),@(way.version),@(way.changeset),@(way.userId),@(way.visible),way.user,way.action,way.timeStamp];
        
        //Delete Tags
        NSString *deleteTagString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE way_id = ?",[[self class] osmk_tagTableNameForObject:way]];
        BOOL tagDeleteResult = [self executeUpdate:deleteTagString,@(way.osmId)];
        
        
        //INsert new tags
        __block BOOL tagInsertResult = YES;
        [way.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *insertString = [NSString stringWithFormat:@"INSERT INTO %@ (way_id, key, value) VALUES (?,?,?)",[[self class] osmk_tagTableNameForObject:way]];
            tagInsertResult = [self executeUpdate:insertString,@(way.osmId),key,obj];
            if (!tagInsertResult) {
                *stop = YES;
            }
        }];
        
        if (!(tagDeleteResult && tagInsertResult && wayResult && nodeInsertResult && deleteNodesResult)) {
            //FIXME error
        }
        return YES;
    }
    return NO;
}

- (BOOL)osmk_saveRelation:(OSMKRelation *)relation error:(NSError **)error
{
    if ([relation isKindOfClass:[OSMKRelation class]]) {
        
        NSString *insertString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (relation_id,version,changeset,user_id,visible,user,action,time_stamp) VALUES (?,?,?,?,?,?,?,?)",[[self class] osmk_tableNameForObject:relation]];
        BOOL insertRelationResult = [self executeUpdate:insertString,@(relation.osmId),@(relation.version),@(relation.changeset),@(relation.userId),@(relation.visible),relation.user,@(relation.action),relation.timeStamp];
        
        BOOL deleteRelationMembersResults = [self executeUpdateWithFormat:@"DELETE FROM relation_member WHERE relation_id = %lld",relation.osmId];
        __block BOOL insertMembersResult = YES;
        [relation.members enumerateObjectsUsingBlock:^(OSMKRelationMember *member, NSUInteger idx, BOOL *stop) {
            
            insertMembersResult = [self executeUpdateWithFormat:@"INSERT INTO relation_member (relation_id,type,ref,role,local_order) VALUES (%lld,%@,%lld,%@,%ld)",relation.osmId,[OSMKObject stringForType:member.type],member.ref,member.role,idx];
            
        }];
        
        NSString *tagDeleteString = [NSString stringWithFormat:@"DELETE FROM %@ WHERE relation_id = ?",[[self class] osmk_tagTableNameForObject:relation]];
        BOOL deleteTagsResult = [self executeUpdate:tagDeleteString,@(relation.osmId)];
        
        __block BOOL tagInsertResult = YES;
        [relation.tags enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *tagInsertString = [NSString stringWithFormat:@"INSERT INTO %@ (relation_id, key, value) VALUES (?,?,?)",[[self class] osmk_tagTableNameForObject:relation]];
            tagInsertResult = [self executeUpdate:tagInsertString,@(relation.osmId),key,obj];
            if (!tagInsertResult) {
                *stop = YES;
            }
        }];
        
        if (!(deleteTagsResult && tagInsertResult && insertMembersResult && insertRelationResult &&deleteRelationMembersResults)) {
            //FIXME ERROR
        }
        return YES;
    }
    return NO;
}

- (BOOL)osmk_saveUser:(OSMKUser *)user error:(NSError **)error
{
    BOOL result = NO;
    if (user) {
        BOOL insertResult = [self executeUpdateWithFormat:@"INSERT OR REPLACE INTO user (user_id,display_name,date_created,image_url,user_description,terms_agreed,changeset_count,trace_count,received_blocks,active_received_blocks,issued_blocks,active_issued_blocks) VALUES (%lld,%@,%@,%@,%@,%d,%d,%d,%d,%d,%d,%d)",user.osmId,user.displayName,user.dateCreated,user.imageUrl,user.userDescription,user.termsAgreed,user.changesetCount,user.traceCount,user.receivedBlocks,user.activeReceivedBlocks,user.issuedBlocks,user.activeIssuedBlocks];
        
        BOOL deleteResult = [self executeUpdateWithFormat:@"DELETE FROM user_roles WHERE user_id = %lld",user.osmId];
        
        
        __block BOOL updateRoles = YES;
        [user.roles enumerateObjectsUsingBlock:^(NSString *role, BOOL *stop) {
            updateRoles = [self executeUpdateWithFormat:@"INSERT INTO user_roles (user_id,role) VALUES (%lld,%@)",user.osmId,role];
            
            if (!updateRoles) {
                *stop = YES;
            }
        }];
        
        result = insertResult && deleteResult && updateRoles;
    }
    
    return result;
}

- (BOOL)osmk_saveNote:(OSMKNote *)note error:(NSError **)error
{
    BOOL result = NO;
    
    if (note) {
        NSString *geomString = [NSString stringWithFormat:@"GeomFromText('POINT(%f %f)', 4326)",note.latitude, note.longitude];
        NSString *updateString = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (note_id,open,date_created,date_closed,geom) VALUES (?,?,?,?,%@)",[[self class] osmk_tableNameForObject:note],geomString];
        BOOL noteResult = [self executeUpdate:updateString,@(note.osmId),@(note.isOpen),note.dateCreated,note.dateClosed];
        
        BOOL deleteCommentsResult = [self executeUpdateWithFormat:@"DELETE FROM note_comments WHERE note_id = %lld",note.osmId];
        
        __block BOOL insertCommentsReults = YES;
        [note.commentsArray enumerateObjectsUsingBlock:^(OSMKComment *comment, NSUInteger idx, BOOL *stop) {
            
            insertCommentsReults = [self executeUpdateWithFormat:@"INSERT INTO note_comments (note_id,user_id,user,date,text,action,local_order) VALUES (%lld,%lld,%@,%@,%@,%@,%d)",note.osmId,comment.userId,comment.user,comment.date,comment.text,comment.action,idx];
            
            if (!insertCommentsReults) {
                *stop = YES;
            }
            
        }];
        
        result = noteResult && deleteCommentsResult && insertCommentsReults;
    }
    
    return result;
}

#pragma - mark Fetching Methods

- (OSMKNode *)osmk_nodeWithOsmId:(int64_t)nodeId
{
    OSMKNode *node = [self osmk_elementForType:OSMKElementTypeNode elementId:nodeId];
    if (node) {
        node.tags = [self osmk_tagsForElementType:OSMKElementTypeNode elementId:node.osmId];
    }
    
    return node;
}

- (OSMKWay *)osmk_wayWithOsmId:(int64_t)osmId
{
    OSMKWay *way = [self osmk_elementForType:OSMKElementTypeWay elementId:osmId];
    if (way) {
        way.tags = [self osmk_tagsForElementType:OSMKElementTypeWay elementId:osmId];
        
        FMResultSet *resultSet = [self executeQueryWithFormat:@"SELECT * FROM way_node WHERE way_id = %lld ORDER BY local_order",osmId];
        
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

- (OSMKRelation *)osmk_relationWithOsmId:(int64_t)osmId
{
    OSMKRelation *relation = [self osmk_elementForType:OSMKElementTypeRelation elementId:osmId];
    if (relation) {
        relation.tags = [self osmk_tagsForElementType:OSMKElementTypeRelation elementId:osmId];
        
        FMResultSet *resultSet = [self executeQueryWithFormat:@"SELECT * FROM relation_member WHERE relation_id = %lld ORDER BY local_order",osmId];
        
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

- (id)osmk_elementForType:(OSMKElementType)elementType elementId:(int64_t)elementId
{
    NSString *tableName = [NSString stringWithFormat:@"%@s",[OSMKObject stringForType:elementType]];
    NSString *idColumnName = [NSString stringWithFormat:@"%@_id",[OSMKObject stringForType:elementType]];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %lld LIMIT 1",tableName,idColumnName,elementId];
    
    FMResultSet *resultSet = [self executeQuery:query];
    OSMKObject *object = nil;
    if (resultSet.next) {
        object = (OSMKObject *)[OSMKObject objectForType:elementType elementId:elementId];
        
        object.action = [resultSet intForColumn:@"action"];
        object.changeset = [resultSet longForColumn:@"changeset"];
        //FIXME object.timeStamp = [resultSet dateForColumn:@"time_stamp"];
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

- (NSDictionary *)osmk_tagsForElementType:(OSMKElementType)elementType elementId:(int64_t)elementId
{
    NSString *tableName = [NSString stringWithFormat:@"%@s_tags",[OSMKObject stringForType:elementType]];
    NSString *idColumnName = [NSString stringWithFormat:@"%@_id",[OSMKObject stringForType:elementType]];
    
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %lld",tableName,idColumnName,elementId];
    FMResultSet *resultSet = [self executeQuery:query];
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

- (OSMKUser *)osmk_userWithOsmId:(int64_t)osmId
{
    OSMKUser *user = [[OSMKUser alloc] initWIthOsmId:osmId];
    
    FMResultSet *resultsSet = [self executeQueryWithFormat:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE user_id = %lld LIMIT 1",[[self class] osmk_tableNameForObject:user],osmId]];
    if ([resultsSet next]) {
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
    } else {
        user = nil;
    }
    
    if (user) {
        FMResultSet *rolesResultSet = [self executeQueryWithFormat:@"SELECT * FROM user_roles WHERE user_id = %lld",osmId];
        
        NSMutableSet *roleMutableSet = [NSMutableSet set];
        while ([rolesResultSet next]) {
            NSString *role = [rolesResultSet stringForColumn:@"role"];
            if ([role length]) {
                [roleMutableSet addObject:role];
            }
        }
        user.roles = [roleMutableSet copy];
    }

    return user;
}

- (OSMKNote *)noteWithOsmId:(int64_t)osmId
{
    __block OSMKNote *note = [[OSMKNote alloc] init];;
        
    FMResultSet *resultSet = [self executeQueryWithFormat:[NSString stringWithFormat:@"SELECT * from %@ where note_id = %lld LIMIT 1",[[self class] osmk_tableNameForObject:note],osmId]];
    
    if ([resultSet next]) {
        note.osmId = osmId;
        note.isOpen = [resultSet boolForColumn:@"open"];
        note.dateCreated = [resultSet dateForColumn:@"date_created"];
        note.dateClosed = [resultSet dateForColumn:@"date_closed"];
        ShapeKitPoint *point = [resultSet objectForColumnName:@"geom"];
        note.coordinate = point.coordinate;
    }
    else {
        note = nil;
    }
    
    if (note) {
        resultSet = [self executeQueryWithFormat:@"SELECT * FROM note_comment WHERE note_id = %lld ORDER BY local_order",osmId];
        
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
    
    return note;
}


- (CLLocationCoordinate2D)osmk_coordinateOfNodeWithId:(int64_t)nodeId
{
    NSString *queryString = [NSString stringWithFormat:@"SELECT geom FROM %@ WHERE node_id = ? LIMIT 1",OSMKNodeElementName];
    FMResultSet *resultSet = [self executeQuery:queryString,@(nodeId)];
    
    while (resultSet.next) {
        ShapeKitPoint *point = [resultSet objectForColumnName:@"geom"];
        return point.coordinate;
    }
    return CLLocationCoordinate2DMake(DBL_MAX, DBL_MAX);
}

#pragma - mark Class Methods

+ (NSString *)osmk_tableNameForObject:(id)object
{
    if ([object isKindOfClass:[OSMKNode class]]) {
        return OSMKNodeElementName;
    }
    else if ([object isKindOfClass:[OSMKWay class]]) {
        return OSMKWayElementName;
    }
    else if ([object isKindOfClass:[OSMKRelation class]]) {
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

+ (NSString *)osmk_tagTableNameForObject:(OSMKObject *)object
{
    return [[self osmk_tableNameForObject:object] stringByAppendingFormat:@"_%@",OSMKTagElementName];
}

@end

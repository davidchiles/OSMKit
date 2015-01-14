//
//  OSMKImporter.m
//  Pods
//
//  Created by David Chiles on 1/13/15.
//
//

#import "OSMKImporter.h"
#import "FMDatabase+OSMKitSpatiaLite.h"
#import <SpatialDBKit/SpatialDatabaseQueue.h>
#import "FMDB.h"
#import "OSMKTBXMLParser.h"

@interface OSMKImporter ()

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@property (nonatomic, strong) dispatch_queue_t serialWorkQueue;

@end

@implementation OSMKImporter

- (id)init
{
    if (self = [super init]) {
        
        NSString *queueString  = [NSString stringWithFormat:@"%@-work",NSStringFromClass([self class])];
        self.serialWorkQueue = dispatch_queue_create([queueString UTF8String], 0);
    }
    return self;
}

- (BOOL)setupDatbaseWithPath:(NSString *)path overwrite:(BOOL)overwrite
{
    if ([path length]) {
        self.databaseQueue = [[SpatialDatabaseQueue alloc] initWithPath:path];
        __block BOOL success = NO;
        [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            success = [db osmk_setupDatabaseWithOverwrite:overwrite];
        }];
    }
}

- (void)asyncSetupDatbaseWithPath:(NSString *)path overwrite:(BOOL)overwrite completion:(void (^)(BOOL success))completionBlock completionQueue:(dispatch_queue_t)completionQueue;
{
    if (!completionQueue) {
        __block completionQueue = dispatch_get_main_queue();
    }
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        __block BOOL success = [strongSelf setupDatbaseWithPath:path overwrite:overwrite];
        if (completionBlock) {
            dispatch_sync(completionQueue, ^{
                completionBlock(success);
            });
        }
    });
}

#pragma - mark Import Methods

- (void)importXMLData:(NSData *)xmlData completion:(void (^)(void))completionBlock completionQueue:(dispatch_queue_t)completionQueue;
{
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    
    dispatch_async(concurrentQueue, ^{
        dispatch_group_t nodeGroup = dispatch_group_create();
        dispatch_group_t wayGroup = dispatch_group_create();
        __block NSArray *parsedWays = nil;
        __block NSArray *parsedRelations = nil;
        
        dispatch_group_enter(wayGroup);
        
        __block OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:xmlData error:nil];
        
        dispatch_group_async(nodeGroup, concurrentQueue, ^{
            //Parse all nodes
            NSArray *nodes = [parser parseNodes];
            //Store all nodes
            NSLog(@"Finished Parsing Nodes");
            [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [nodes enumerateObjectsUsingBlock:^(OSMKNode *node, NSUInteger idx, BOOL *stop) {
                    [db osmk_saveNode:node error:nil];
                }];
            }];
            NSLog(@"Finished Saving Nodes");
        });
        
        dispatch_group_async(nodeGroup, concurrentQueue, ^{
            //Parse all ways
            parsedWays = [parser parseWays];
            NSLog(@"Fnished Parsing Ways");
        });
        
        dispatch_group_notify(nodeGroup, concurrentQueue, ^{
            //Once nodes have been stored & ways have been parsed
            //Save ways
            dispatch_group_async(wayGroup, concurrentQueue, ^{
                [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                    [parsedWays enumerateObjectsUsingBlock:^(OSMKWay *way, NSUInteger idx, BOOL *stop) {
                        [db osmk_saveWay:way error:nil];
                    }];
                }];
                dispatch_group_leave(wayGroup);
                NSLog(@"Finished Saving Ways");
            });
            
        });
        
        dispatch_group_async(wayGroup, concurrentQueue, ^{
            parsedRelations = [parser parseRelations];
            NSLog(@"Finished Parsing Relations");
        });
        
        dispatch_group_notify(wayGroup, concurrentQueue, ^{
            //Once ways have been stored & relatoins parsed
            //Save relations
            [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                [parsedRelations enumerateObjectsUsingBlock:^(OSMKRelation *relation, NSUInteger idx, BOOL *stop) {
                    [db osmk_saveRelation:relation error:nil];
                }];
            }];
            NSLog(@"Finished Saving Relations");
            
            if (completionBlock) {
                dispatch_async(completionQueue, completionBlock);
            }
        });
    });
    
    
}

@end

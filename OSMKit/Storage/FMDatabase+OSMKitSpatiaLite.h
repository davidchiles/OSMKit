//
//  FMDatabase+OSMKit.h
//  Pods
//
//  Created by David Chiles on 12/15/14.
//
//

#import "FMDatabase.h"
#import <CoreLocation/CoreLocation.h>

@class OSMKObject, OSMKNode, OSMKWay, OSMKRelation, OSMKUser, OSMKNote;

@interface FMDatabase (OSMKitSpatiaLite)

- (BOOL)osmk_setupDatabaseWithOverwrite:(BOOL)overwrite;

- (BOOL)osmk_saveNode:(OSMKNode *)node error:(NSError **)error;
- (BOOL)osmk_saveWay:(OSMKWay *)way error:(NSError **)error;
- (BOOL)osmk_saveRelation:(OSMKRelation *)relation error:(NSError **)error;
- (BOOL)osmk_saveUser:(OSMKUser *)user error:(NSError **)error;
- (BOOL)osmk_saveNote:(OSMKNote *)note error:(NSError **)error;

- (OSMKNode *)osmk_nodeWithOsmId:(int64_t)osmId;
- (OSMKWay *)osmk_wayWithOsmId:(int64_t)osmId;
- (OSMKRelation *)osmk_relationWithOsmId:(int64_t)osmId;
- (OSMKUser *)osmk_userWithOsmId:(int64_t)osmId;
- (OSMKNote *)osmk_noteWithOsmId:(int64_t)osmId;

- (CLLocationCoordinate2D)osmk_coordinateOfNodeWithId:(int64_t)nodeId;

+ (NSString *)osmk_tableNameForObject:(id)object;
+ (NSString *)osmk_tagTableNameForObject:(OSMKObject *)object;

@end

//
//  OSMKParser.h
//  Pods
//
//  Created by David Chiles on 12/28/14.
//
//

@protocol OSMKParserProtocol <NSObject>

- (NSArray *)parseNodes;
- (NSArray *)parseWays;
- (NSArray *)parseRelations;

- (NSArray *)parseUsers;
- (NSArray *)parseNotes;

@end

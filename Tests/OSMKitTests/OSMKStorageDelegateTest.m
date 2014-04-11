//
//  OSMKStorageDelegateTest.m
//  OSMKit
//
//  Created by David Chiles on 4/11/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKStorageDelegateTest.h"

@implementation OSMKStorageDelegateTest


- (id)init
{
    if (self = [super init]) {
        self.nodesCount = 0;
        self.waysCount = 0;
        self.relationsCount = 0;
        self.usersCount = 0;
        self.notesCount = 0;
    }
    return self;
}

#pragma - mark OSMKStorageDelegate Methodsd

- (void)storageDidStartImporting:(OSMKStorage *)storage
{
//	self.nodesCount = 0;
//    self.waysCount = 0;
//    self.relationsCount = 0;
//    self.usersCount = 0;
//    self.notesCount = 0;
}
- (void)storage:(OSMKStorage *)storage didSaveNodes:(NSArray *)nodes
{
	self.nodesCount += [nodes count];
}
- (void)storage:(OSMKStorage *)storage didSaveWays:(NSArray *)ways
{
	self.waysCount += [ways count];
}
- (void)storage:(OSMKStorage *)storage didSaveRelations:(NSArray *)relations
{
	self.relationsCount += [relations count];
}
- (void)storage:(OSMKStorage *)storage didSaveUsers:(NSArray *)users
{
	self.usersCount += [users count];
}
- (void)storage:(OSMKStorage *)storage didSaveNotes:(NSArray *)notes
{
    self.notesCount += [notes count];
	
}
- (void)storageDidFinishImporting:(OSMKStorage *)storage
{
    if (self.completionBlock) {
        self.completionBlock();
    }
}

@end

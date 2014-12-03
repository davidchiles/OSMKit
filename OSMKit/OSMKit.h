//
//  OSMKit.h
//  OSMKit
//
//  Created by David Chiles on 12/2/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//



        #import "OSMKNode.h"
        #import "OSMKWay.h"
        #import "OSMKRelation.h"
        #import "OSMKRelationMember.h"
        #import "OSMKUser.h"
        #import "OSMKNote.h"
        #import "OSMKComment.h"

        typedef void (^OSMKElementsCompletionBlock)(NSArray *nodes, NSArray *ways, NSArray *relations);
        typedef void (^OSMKNotesCompletionBlock)(NSArray *notes);
        typedef void (^OSMKUsersCompletionBlock)(NSArray *users);
        typedef void (^OSMKErrorBlock)(NSError *users);



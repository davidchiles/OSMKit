//
//  OSMKOnoXMLParseOperation.m
//  OSMKit
//
//  Created by David Chiles on 12/2/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKOnoXMLParseOperation.h"
#import "Ono.h"

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "OSMKUser.h"
#import "OSMKNote.h"
#import "OSMKComment.h"

@implementation OSMKOnoXMLParseOperation


- (void)main {
    
    NSError *error = nil;
    ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:self.data error:&error];
    if (document.rootElement && !error) {
        
        __block NSArray *nodes = nil;
        __block NSArray *ways = nil;
        __block NSArray *relations = nil;
        __block NSArray *notes = nil;
        __block NSArray *users = nil;
        
        dispatch_group_t parseDispatchGroup = dispatch_group_create();
        
        dispatch_queue_t nodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_async(parseDispatchGroup, nodeQueue, ^{
            nodes = [self findNodes:document.rootElement];
        });
        
        dispatch_queue_t wayQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_async(parseDispatchGroup, wayQueue, ^{
            ways = [self findWays:document.rootElement];
        });
        
        dispatch_queue_t relationQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_async(parseDispatchGroup, relationQueue, ^{
            relations = [self findRelations:document.rootElement];
        });
        
        dispatch_queue_t userQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_async(parseDispatchGroup, userQueue, ^{
            users = [self findUsers:document.rootElement];
        });
        
        dispatch_queue_t noteQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_async(parseDispatchGroup, noteQueue, ^{
            notes = [self findNotes:document.rootElement];
        });
        
        dispatch_group_wait(parseDispatchGroup, DISPATCH_TIME_FOREVER);
        
        dispatch_queue_t completionQueue = self.completionQueue ?: dispatch_get_main_queue();
        
        [self completedParsingNodes:nodes ways:ways relations:relations error:error completionQueue:completionQueue];
        [self completedParsingNotes:notes error:error completionQueue:completionQueue];
        [self completedParsingUsers:users error:error completionQueue:completionQueue];
    }
    
}

- (void)completedParsingUsers:(NSArray *)users error:(NSError *)error completionQueue:(dispatch_queue_t)completionQueue
{
    if (self.usersCompletionBlock) {
        dispatch_async(completionQueue, ^{
            self.usersCompletionBlock(users);
        });
    }
}

- (void)completedParsingNotes:(NSArray *)notes error:(NSError *)error completionQueue:(dispatch_queue_t)completionQueue
{
    if (self.notesCompletionBlock) {
        dispatch_async(completionQueue, ^{
            self.notesCompletionBlock(notes);
        });
    }
}

- (void)completedParsingNodes:(NSArray *)nodes ways:(NSArray *)ways relations:(NSArray *)relations error:(NSError *)error completionQueue:(dispatch_queue_t)completionQueue
{
    if (self.elementsCompletionBlock) {
        dispatch_async(completionQueue, ^{
            self.elementsCompletionBlock(nodes,ways,relations);
        });
    }
}

- (NSDictionary *)tagsDictioanryWithElement:(ONOXMLElement *)element
{
    NSMutableDictionary *tagsDictionary = [NSMutableDictionary new];
    [element enumerateElementsWithXPath:OSMKTagElementName usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
        NSString *key = [element valueForAttribute:@"k"];
        NSString *value = [element valueForAttribute:@"v"];
        
        if ([value length] && [key length]) {
            [tagsDictionary setObject:value forKey:key];
        }
    }];
    
    return tagsDictionary;
}

- (NSArray *)findNodes:(ONOXMLElement *)rootElement
{
    NSMutableArray *nodes = nil;
    if (rootElement) {
        nodes = [NSMutableArray new];
        
        [rootElement enumerateElementsWithXPath:OSMKNodeElementName usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            OSMKNode *node = [[OSMKNode alloc] initWithAttributesDictionary:[element attributes]];
            node.tags = [self tagsDictioanryWithElement:element];
            [nodes addObject:node];
        }];
    }
    
    if (![nodes count]) {
        nodes = nil;
    }
    return nodes;
}

- (NSArray *)findWays:(ONOXMLElement *)rootElement
{
    NSMutableArray *ways = nil;
    if (rootElement) {
        ways = [NSMutableArray new];
        
        [rootElement enumerateElementsWithXPath:OSMKWayElementName usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            OSMKWay *way = [[OSMKWay alloc] initWithAttributesDictionary:[element attributes]];
            way.tags = [self tagsDictioanryWithElement:element];
            
            NSMutableArray *nodes = [NSMutableArray new];
            [element enumerateElementsWithXPath:OSMKWayNodeElementName usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
                NSNumber *nodeId = @([[element valueForAttribute:@"ref"] longLongValue]);
                if (nodeId) {
                    [nodes addObject:nodeId];
                }
            }];
            
            way.nodes = nodes;
            
            [ways addObject:way];
        }];
    }
    
    if (![ways count]) {
        ways = nil;
    }
    return ways;
}

- (NSArray *)findRelations:(ONOXMLElement *)rootElement
{
    NSMutableArray *relations = nil;
    if (rootElement) {
        relations = [NSMutableArray new];
        
        [rootElement enumerateElementsWithXPath:OSMKRelationElementName usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            OSMKRelation *relation = [[OSMKRelation alloc] initWithAttributesDictionary:[element attributes]];
            relation.tags = [self tagsDictioanryWithElement:element];
            
            NSMutableArray *members = [NSMutableArray new];
            
            [element enumerateElementsWithXPath:OSMKRelationMemberElementName
                                     usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
                                         
                                         OSMKRelationMember *member = [[OSMKRelationMember alloc] initWithAttributesDictionary:[element attributes]];
                                         if (member) {
                                             [members addObject:member];
                                         }
                
            }];
            
            relation.members = members;
            
            [relations addObject:relation];
        }];
    }
    
    if (![relations count]) {
        relations = nil;
    }
    return relations;
}

- (NSArray *)findUsers:(ONOXMLElement *)rootElement
{
    NSMutableArray *users = nil;
    if (rootElement) {
        users = [NSMutableArray new];
        
        [rootElement enumerateElementsWithXPath:OSMKUserElementName usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            OSMKUser *user = [self parseUser:element];
            if (user) {
                [users addObject:user];
            }
        }];
    }
    
    if (![users count]) {
        users = nil;
    }
    return users;
}

- (OSMKUser *)parseUser:(ONOXMLElement *)element
{
    OSMKUser *user = [[OSMKUser alloc] initWithAttributesDictionary:[element attributes]];
    user.userDescription = [[element firstChildWithXPath:@"description"] stringValue];
    user.termsAgreed = [[[element firstChildWithXPath:@"contributor-terms"] valueForAttribute:@"agreed"] isEqualToString:@"true"];
    user.imageUrl = [NSURL URLWithString:[[element firstChildWithXPath:@"img"] valueForAttribute:@"href"]];
    user.changesetCount = [[[element firstChildWithXPath:@"changesets"] valueForAttribute:@"count"] integerValue];
    user.traceCount = [[[element firstChildWithXPath:@"traces"] valueForAttribute:@"count"] integerValue];
    
    NSMutableSet *roleSet = [NSMutableSet new];
    NSArray *roles = [[element firstChildWithXPath:@"roles"] children];
    [roles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[ONOXMLElement class]]) {
            NSString *role = ((ONOXMLElement *)obj).tag;
            if (role) {
                [roleSet addObject:role];
            }
        }
    }];
    user.roles = roleSet;
    
    ONOXMLElement *receivedElement = [element firstChildWithXPath:@"blocks/received"];
    user.receivedBlocks = [[receivedElement valueForAttribute:@"count"] integerValue];
    user.activeReceivedBlocks = [[receivedElement valueForAttribute:@"active"] integerValue];
    
    ONOXMLElement *issuedElement = [element firstChildWithXPath:@"blocks/issued"];
    user.issuedBlocks = [[issuedElement valueForAttribute:@"count"] integerValue];
    user.activeIssuedBlocks = [[issuedElement valueForAttribute:@"active"] integerValue];
    
    return user;
}

- (NSArray *)findNotes:(ONOXMLElement *)rootElement
{
    NSMutableArray *notes = nil;
    if (rootElement) {
        notes = [NSMutableArray new];
        
        [rootElement enumerateElementsWithXPath:OSMKNoteElementName usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            OSMKNote *note = [self parseNote:element];
            if (note) {
                [notes addObject:note];
            }
        }];
    }
    
    if (![notes count]) {
        notes = nil;
    }
    return notes;
}

- (OSMKNote *)parseNote:(ONOXMLElement *)element
{
    OSMKNote *note = [[OSMKNote alloc] init];
    
    note.osmId = [[[element firstChildWithTag:@"id"] numberValue] longLongValue];
    CLLocationDegrees lat = [[element valueForAttribute:@"lat"] doubleValue];
    CLLocationDegrees lon = [[element valueForAttribute:@"lon"] doubleValue];
    note.coordinate = CLLocationCoordinate2DMake(lat, lon);
    
    note.dateCreated = [[element firstChildWithTag:@"date_created"] dateValue];
    note.dateClosed = [[element firstChildWithTag:@"date_closed"] dateValue];
    
    note.isOpen = [[[element firstChildWithTag:@"status"] stringValue] isEqualToString:@"open"];
    
    NSMutableArray *comments = [NSMutableArray new];
    [element enumerateElementsWithXPath:@"comments/comment" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
        OSMKComment *comment = [self parseComment:element];
        comment.noteId = note.osmId;
        if (comment) {
            [comments addObject:comment];
        }
        
    }];
    
    note.commentsArray = comments;
    
    return note;
}

- (OSMKComment *)parseComment:(ONOXMLElement *)element
{
    OSMKComment *comment = [[OSMKComment alloc] init];
    comment.userId = [[[element firstChildWithXPath:@"uid"] numberValue] longLongValue];
    comment.date = [[element firstChildWithXPath:@"date"] dateValue];
    comment.user = [[element firstChildWithXPath:@"user"] stringValue];
    comment.action = [[element firstChildWithXPath:@"action"] stringValue];
    comment.text = [[element firstChildWithXPath:@"text"] stringValue];
    
    return comment;
}

@end

//
//  OSMKTBXMLParser.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKTBXMLParseOperation.h"
#import "TBXML.h"

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "OSMKUser.h"
#import "OSMKNote.h"
#import "OSMKComment.h"

@interface OSMKTBXMLParseOperation ()

@property (nonatomic) dispatch_queue_t parseQueue;

@end

@implementation OSMKTBXMLParseOperation

- (id)init {
    if (self = [super init]) {
        NSString *queueString = [NSString stringWithFormat:@"%@-parse",NSStringFromClass([self class])];
        self.parseQueue = dispatch_queue_create([queueString UTF8String], 0);
    }
    return self;
}

- (void)main
{
    dispatch_queue_t queue = self.completionQueue ?: dispatch_get_main_queue();
    [self parseXMLData:self.data completionQueue:queue];
}

- (void)parseXMLData:(NSData *)xmlData completionQueue:(dispatch_queue_t)completionQueue
{
    NSError *error = nil;
    TBXML *parser = [[TBXML alloc] initWithXMLData:xmlData error:&error];
    if (error) {
        NSLog(@"ERROR - %@",error);
    }
    [self parse:parser completionQueue:completionQueue];
}

- (void)parse:(TBXML *)xmlParser completionQueue:(dispatch_queue_t)completionQueue{
    TBXMLElement *rootElement = xmlParser.rootXMLElement;
    NSArray *nodes = nil;
    NSArray *ways = nil;
    NSArray *relations = nil;
    NSArray *notes = nil;
    NSArray *users = nil;
    NSError *error = nil;
    if (rootElement) {
        
        nodes = [self findNodesWithRootElement:rootElement];
        ways = [self findWaysWithRootElement:rootElement];
        relations = [self findRelationsWithRootElement:rootElement];
        [self completedParsingNodes:nodes ways:ways relations:relations error:error completionQueue:completionQueue];
        
        users = [self findUsersWithRootElement:rootElement];
        [self completedParsingUsers:users error:error completionQueue:completionQueue];
        
        notes = [self findNotesWithRootElement:rootElement];
        [self completedParsingNotes:notes error:error completionQueue:completionQueue];
    }
}

- (void)completedParsingUsers:(NSArray *)users error:(NSError *)error completionQueue:(dispatch_queue_t)completionQueue
{
    if (self.usersCompletionBlock) {
        dispatch_async(completionQueue, ^{
            self.usersCompletionBlock(users,error);
        });
    }
}

- (void)completedParsingNotes:(NSArray *)notes error:(NSError *)error completionQueue:(dispatch_queue_t)completionQueue
{
    if (self.notesCompletionBlock) {
        dispatch_async(completionQueue, ^{
            self.notesCompletionBlock(notes,error);
        });
    }
}

- (void)completedParsingNodes:(NSArray *)nodes ways:(NSArray *)ways relations:(NSArray *)relations error:(NSError *)error completionQueue:(dispatch_queue_t)completionQueue
{
    if (self.elementsCompletionBlock) {
        dispatch_async(completionQueue, ^{
            self.elementsCompletionBlock(nodes,ways,relations,nil);
        });
    }
}

- (NSDictionary *)attributesDictionaryWithElement:(TBXMLElement *)element
{
    NSMutableDictionary *elementDict = [[NSMutableDictionary alloc] init];
    
    TBXMLAttribute *attribute = element->firstAttribute;
    while (attribute) {
        [elementDict setObject:[TBXML attributeValue:attribute] forKey:[TBXML attributeName:attribute]];
        attribute = attribute->next;
    }
    return elementDict;
}

- (NSDictionary *)tagsDictioanryWithElement:(TBXMLElement *)element
{
    TBXMLElement* tagElement = [TBXML childElementNamed:@"tag" parentElement:element];
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    while (tagElement)
    {
        NSString* key = [TBXML valueOfAttributeNamed:@"k" forElement:tagElement];
        NSString* value = [TBXML valueOfAttributeNamed:@"v" forElement:tagElement];
        
        [dictionary setObject:value forKey:key];
        tagElement = [TBXML nextSiblingNamed:@"tag" searchFromElement:tagElement];
    }
    
    return dictionary;
}

- (NSArray *)wayNodesWithElement:(TBXMLElement *)element
{
    TBXMLElement *ndElement = [TBXML childElementNamed:@"nd" parentElement:element];
    NSMutableArray *mutableArray = [NSMutableArray array];
    
    while (ndElement) {
        
        NSNumber *ref = @([[TBXML valueOfAttributeNamed:@"ref" forElement:ndElement] longLongValue]);
        [mutableArray addObject:ref];
        
        
        ndElement = [TBXML nextSiblingNamed:@"nd" searchFromElement:ndElement];
    }
    return mutableArray;
}

- (NSArray *)relationMembersWithElement:(TBXMLElement *)element
{
    TBXMLElement *memberElement = [TBXML childElementNamed:OSMKRelationMemberElementName parentElement:element];
    NSMutableArray *mutableArray = [NSMutableArray array];
    
    while (memberElement) {
        OSMKRelationMember *member = [[OSMKRelationMember alloc] initWithAttributesDictionary:[self attributesDictionaryWithElement:memberElement]];
        if (member) {
            [mutableArray addObject:member];
        }
        
        memberElement = [TBXML nextSiblingNamed:OSMKRelationMemberElementName searchFromElement:memberElement];
    }
    return mutableArray;
}

- (NSArray *)findNodesWithRootElement:(TBXMLElement *)rootElement
{
    NSMutableArray *nodes = [NSMutableArray new];
    TBXMLElement * nodeXML = [TBXML childElementNamed:OSMKNodeElementName parentElement:rootElement];
    while (nodeXML) {
        OSMKNode *node = [[OSMKNode alloc] initWithAttributesDictionary:[self attributesDictionaryWithElement:nodeXML]];
        node.tags = [self tagsDictioanryWithElement:nodeXML];
        if (node) {
            [nodes addObject:node];
        }
        nodeXML = [TBXML nextSiblingNamed:OSMKNodeElementName searchFromElement:nodeXML];
    }
    
    if (![nodes count]) {
        nodes = nil;
    }
    
    return nodes;
}

- (NSArray *)findWaysWithRootElement:(TBXMLElement *)rootElement
{
    NSMutableArray *ways = [NSMutableArray new];
    TBXMLElement *wayXML = [TBXML childElementNamed:OSMKWayElementName parentElement:rootElement];
    while (wayXML) {
        OSMKWay *way = [[OSMKWay alloc] initWithAttributesDictionary:[self attributesDictionaryWithElement:wayXML]];
        way.tags = [self tagsDictioanryWithElement:wayXML];
        way.nodes = [self wayNodesWithElement:wayXML];
        
        if (way) {
            [ways addObject:way];
        }
        
        wayXML = [TBXML nextSiblingNamed:OSMKWayElementName searchFromElement:wayXML];
    }
    if (![ways count]) {
        ways = nil;
    }
    return ways;
}

- (NSArray *)findRelationsWithRootElement:(TBXMLElement *)rootElement
{
    NSMutableArray *relations = [NSMutableArray new];
    TBXMLElement *relationXML = [TBXML childElementNamed:OSMKRelationElementName parentElement:rootElement];
    while (relationXML) {
        OSMKRelation *relation = [[OSMKRelation alloc] initWithAttributesDictionary:[self attributesDictionaryWithElement:relationXML]];
        relation.tags = [self tagsDictioanryWithElement:relationXML];
        relation.members = [self relationMembersWithElement:relationXML];
        
        if (relation) {
            [relations addObject:relation];
        }
        
        relationXML = [TBXML nextSiblingNamed:OSMKRelationElementName searchFromElement:relationXML];
    }
    
    if (![relations count]) {
        relations = nil;
    }
    return relations;
}

- (NSArray *)findUsersWithRootElement:(TBXMLElement *)rootElement
{
    NSMutableArray *users = [NSMutableArray new];
    TBXMLElement *userXML = [TBXML childElementNamed:OSMKUserElementName parentElement:rootElement];
    while (userXML) {
        OSMKUser *user = [[OSMKUser alloc] initWithAttributesDictionary:[self attributesDictionaryWithElement:userXML]];
        user.userDescription = [TBXML textForElement:[TBXML childElementNamed:@"description" parentElement:userXML]];
        
        NSString *agreed = [TBXML valueOfAttributeNamed:@"agreed" forElement:[TBXML childElementNamed:@"contributor-terms" parentElement:userXML]];
        if ([agreed isEqualToString:@"true"]) {
            user.termsAgreed = YES;
        }
        else {
            user.termsAgreed = NO;
        }
        
        NSString *urlString =[ TBXML valueOfAttributeNamed:@"href" forElement:[TBXML childElementNamed:@"img" parentElement:userXML]];
        if ([urlString length]) {
            user.imageUrl = [NSURL URLWithString:urlString];
        }
        
        TBXMLElement *rolesXML = [TBXML childElementNamed:OSMKUserRolesElementName parentElement:userXML];
        TBXMLElement *role = rolesXML->firstChild;
        NSMutableSet *roleSet = [NSMutableSet set];
        
        while (role) {
            NSString *name = [TBXML elementName:role];
            if ([name length]) {
                [roleSet addObject:name];
            }
            
            role = role->nextSibling;
        }
        
        user.roles = [roleSet copy];
        
        user.changesetCount = [[TBXML valueOfAttributeNamed:@"count" forElement:[TBXML childElementNamed:@"changesets" parentElement:userXML]]integerValue];
        user.traceCount = [[TBXML valueOfAttributeNamed:@"count" forElement:[TBXML childElementNamed:@"traces" parentElement:userXML]] integerValue];
        
        
        user.receivedBlocks = [[TBXML valueOfAttributeNamed:@"count" forElement:[TBXML childElementNamed:@"received" parentElement:[TBXML childElementNamed:@"blocks" parentElement:userXML]]] integerValue];
        user.activeReceivedBlocks = [[TBXML valueOfAttributeNamed:@"active" forElement:[TBXML childElementNamed:@"received" parentElement:[TBXML childElementNamed:@"blocks" parentElement:userXML]]] integerValue];
        user.issuedBlocks = [[TBXML valueOfAttributeNamed:@"count" forElement:[TBXML childElementNamed:@"issued" parentElement:[TBXML childElementNamed:@"blocks" parentElement:userXML]]] integerValue];
        user.activeIssuedBlocks = [[TBXML valueOfAttributeNamed:@"active" forElement:[TBXML childElementNamed:@"issued" parentElement:[TBXML childElementNamed:@"blocks" parentElement:userXML]]] integerValue];
        
        if (user) {
            [users addObject:user];
        }
        
        
        userXML = [TBXML nextSiblingNamed:OSMKUserElementName searchFromElement:userXML];
    }
    
    if (![users count]) {
        users = nil;
    }
    
    return users;
    
}

- (NSArray *)findNotesWithRootElement:(TBXMLElement *)rootElement
{
    NSMutableArray *notes = [NSMutableArray new];
    TBXMLElement *noteXML = [TBXML childElementNamed:OSMKNoteElementName parentElement:rootElement];
    while (noteXML) {
        OSMKNote *note = [[OSMKNote alloc] init];
        double lat = [[TBXML valueOfAttributeNamed:@"lat" forElement:noteXML] doubleValue];
        double lon = [[TBXML valueOfAttributeNamed:@"lon" forElement:noteXML] doubleValue];
        note.coordinate = CLLocationCoordinate2DMake(lat, lon);
        note.osmId = [[TBXML textForElement:[TBXML childElementNamed:@"id" parentElement:noteXML]] longLongValue];
        note.dateCreated = [[OSMKNote defaultDateFormatter] dateFromString:[TBXML textForElement:[TBXML childElementNamed:@"date_created" parentElement:noteXML]]];
        
        TBXMLElement *dateClosedElement = [TBXML childElementNamed:@"date_closed" parentElement:noteXML];
        if (dateClosedElement) {
            note.dateClosed = [[OSMKNote defaultDateFormatter] dateFromString:[TBXML textForElement:dateClosedElement]];
        }
        
        note.isOpen = [[TBXML textForElement:[TBXML childElementNamed:@"status" parentElement:noteXML]] isEqualToString:@"open"];
        
        NSMutableArray *comments = [NSMutableArray array];
        TBXMLElement *commentXML = [TBXML childElementNamed:OSMKNoteCommentsElementName parentElement:noteXML]->firstChild;
        while (commentXML) {
            OSMKComment *comment = [[OSMKComment alloc] init];
            comment.date = [[OSMKNote defaultDateFormatter] dateFromString:[TBXML textForElement:[TBXML childElementNamed:@"date" parentElement:commentXML]]];
            comment.action =[TBXML textForElement:[TBXML childElementNamed:@"action" parentElement:commentXML]];
            comment.text = [TBXML textForElement:[TBXML childElementNamed:@"text" parentElement:commentXML]];
            
            TBXMLElement *userElement = [TBXML childElementNamed:@"user" parentElement:commentXML];
            TBXMLElement *userIdElement = [TBXML childElementNamed:@"uid" parentElement:commentXML];
            if (userElement)
            {
                comment.user = [TBXML textForElement:userElement];
            }
            
            if (userIdElement) {
                comment.userId = [[TBXML textForElement:userElement] longLongValue];
            }
            
            
            comment.userId = [[TBXML textForElement:[TBXML childElementNamed:@"date" parentElement:commentXML]] longLongValue];
            
            [comments addObject:comment];
            
            commentXML = commentXML->nextSibling;
        }
        
        note.commentsArray = [comments copy];
        
        if (note) {
            [notes addObject:note];
        }
        
        noteXML = [TBXML nextSiblingNamed:OSMKNoteElementName searchFromElement:noteXML];
    }
    
    if (![notes count]) {
        notes = nil;
    }
    
    return notes;
   
}

@end

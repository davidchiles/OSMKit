//
//  OSMKTBXMLParser.m
//  Pods
//
//  Created by David Chiles on 12/28/14.
//
//

#import "OSMKTBXMLParser.h"
#import "TBXML+OSMKit.h"
#import "OSMKConstants.h"

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKUser.h"
#import "OSMKNote.h"
#import "OSMKComment.h"

@interface OSMKTBXMLParser ()

@property (nonatomic, strong) TBXML *parser;

@end

@implementation OSMKTBXMLParser

- (instancetype)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if (self = [self init]) {
        self.parser = [[TBXML alloc] initWithXMLData:data error:error];
    }
    return self;
}

- (NSArray *)parseNodes
{
    NSMutableArray *nodes = [[NSMutableArray alloc] init];
    TBXMLElement * nodeXML = [TBXML childElementNamed:OSMKNodeElementName parentElement:self.parser.rootXMLElement];
    while (nodeXML) {
        OSMKNode *node = [[OSMKNode alloc] initWithAttributesDictionary:[TBXML osmk_attributesDictionaryWithElement:nodeXML]];
        node.tags = [TBXML osmk_tagsDictioanryWithElement:nodeXML];
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

- (NSArray *)parseWays
{
    NSMutableArray *ways = [NSMutableArray new];
    TBXMLElement *wayXML = [TBXML childElementNamed:OSMKWayElementName parentElement:self.parser.rootXMLElement];
    while (wayXML) {
        
        OSMKWay *way = [[OSMKWay alloc] initWithAttributesDictionary:[TBXML osmk_attributesDictionaryWithElement:wayXML]];
        way.tags = [TBXML osmk_tagsDictioanryWithElement:wayXML];
        way.nodes = [TBXML osmk_wayNodesWithElement:wayXML];
        
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

- (NSArray *)parseRelations
{
    NSMutableArray *relations = [NSMutableArray new];
    TBXMLElement *relationXML = [TBXML childElementNamed:OSMKRelationElementName parentElement:self.parser.rootXMLElement];
    while (relationXML) {
        OSMKRelation *relation = [[OSMKRelation alloc] initWithAttributesDictionary:[TBXML osmk_attributesDictionaryWithElement:relationXML]];
        relation.tags = [TBXML osmk_tagsDictioanryWithElement:relationXML];
        relation.members = [TBXML osmk_relationMembersWithElement:relationXML];
        
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

- (NSArray *)parseUsers
{
    NSMutableArray *users = [NSMutableArray new];
    TBXMLElement *userXML = [TBXML childElementNamed:OSMKUserElementName parentElement:self.parser.rootXMLElement];
    while (userXML) {
        OSMKUser *user = [[OSMKUser alloc] initWithAttributesDictionary:[TBXML osmk_attributesDictionaryWithElement:userXML]];
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
        
        user.roles = roleSet;
        
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

- (NSArray *)parseNotes
{
    NSMutableArray *notes = [NSMutableArray new];
    TBXMLElement *noteXML = [TBXML childElementNamed:OSMKNoteElementName parentElement:self.parser.rootXMLElement];
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

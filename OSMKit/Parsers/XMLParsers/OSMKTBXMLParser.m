//
//  OSMKTBXMLParser.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKTBXMLParser.h"
#import "TBXML.h"

#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "OSMKUser.h"
#import "OSMKNote.h"
#import "OSMKComment.h"

@interface OSMKTBXMLParser ()

@property (nonatomic) dispatch_queue_t parseQueue;

@end

@implementation OSMKTBXMLParser

- (id)init {
    if (self = [super init]) {
        NSString *queueString = [NSString stringWithFormat:@"%@-parse",NSStringFromClass([self class])];
        self.parseQueue = dispatch_queue_create([queueString UTF8String], 0);
    }
    return self;
}

- (void)parseXMLData:(NSData *)xmlData
{
    NSError *error = nil;
    TBXML *parser = [[TBXML alloc] initWithXMLData:xmlData error:&error];
    if (error) {
        NSLog(@"ERROR - %@",error);
    }
    dispatch_async(self.parseQueue, ^{
        [self parse:parser];
    });
    
}

- (void)parse:(TBXML *)xmlParser{
    TBXMLElement *rootElement = xmlParser.rootXMLElement;
    if (rootElement) {
        
        if ([self.delegate respondsToSelector:@selector(parserDidStart:)]) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parserDidStart:self];
            });
        }
        
        [self findNodesWithRootElement:rootElement];
        [self findWaysWithRootElement:rootElement];
        [self findRelationsWithRootElement:rootElement];
        [self findUsersWithRootElement:rootElement];
        [self findNotesWithRootElement:rootElement];
        
        if ([self.delegate respondsToSelector:@selector(parserDidFinish:)]) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parserDidFinish:self];
            });
        }
        
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
    return [elementDict copy];
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
    
    return [dictionary copy];
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
    return [mutableArray copy];
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
    return [mutableArray copy];
}

- (void)findNodesWithRootElement:(TBXMLElement *)rootElement
{
    TBXMLElement * nodeXML = [TBXML childElementNamed:OSMKNodeElementName parentElement:rootElement];
    while (nodeXML) {
        OSMKNode *node = [[OSMKNode alloc] initWithAttributesDictionary:[self attributesDictionaryWithElement:nodeXML]];
        node.tags = [self tagsDictioanryWithElement:nodeXML];
        
        if ([self.delegate respondsToSelector:@selector(parser:didFindNode:)] && node) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindNode:node];
            });
        }
        nodeXML = [TBXML nextSiblingNamed:OSMKNodeElementName searchFromElement:nodeXML];
    }
}

- (void)findWaysWithRootElement:(TBXMLElement *)rootElement
{
    TBXMLElement *wayXML = [TBXML childElementNamed:OSMKWayElementName parentElement:rootElement];
    while (wayXML) {
        OSMKWay *way = [[OSMKWay alloc] initWithAttributesDictionary:[self attributesDictionaryWithElement:wayXML]];
        way.tags = [self tagsDictioanryWithElement:wayXML];
        way.nodes = [self wayNodesWithElement:wayXML];
        
        if ([self.delegate respondsToSelector:@selector(parser:didFindWay:)] && way) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindWay:way];
            });
        }
        
        wayXML = [TBXML nextSiblingNamed:OSMKWayElementName searchFromElement:wayXML];
    }
}

- (void)findRelationsWithRootElement:(TBXMLElement *)rootElement
{
    TBXMLElement *relationXML = [TBXML childElementNamed:OSMKRelationElementName parentElement:rootElement];
    while (relationXML) {
        OSMKRelation *relation = [[OSMKRelation alloc] initWithAttributesDictionary:[self attributesDictionaryWithElement:relationXML]];
        relation.tags = [self tagsDictioanryWithElement:relationXML];
        relation.members = [self relationMembersWithElement:relationXML];
        
        if ([self.delegate respondsToSelector:@selector(parser:didFindRelation:)] && relation) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindRelation:relation];
            });
        }
        
        relationXML = [TBXML nextSiblingNamed:OSMKRelationElementName searchFromElement:relationXML];
    }
}

- (void)findUsersWithRootElement:(TBXMLElement *)rootElement
{
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
        
        TBXMLElement *rolesXML = [TBXML childElementNamed:@"roles" parentElement:userXML];
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
        
        if ([self.delegate respondsToSelector:@selector(parser:didFindUser:)] && user) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindUser:user];
            });
        }
        
        
        
        userXML = [TBXML nextSiblingNamed:OSMKUserElementName searchFromElement:userXML];
    }
    
}

- (void)findNotesWithRootElement:(TBXMLElement *)rootElement
{
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
        TBXMLElement *commentXML = [TBXML childElementNamed:@"comments" parentElement:noteXML]->firstChild;
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
        
        if ([self.delegate respondsToSelector:@selector(parser:didFindNote:)] && note) {
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindNote:note];
            });
        }
        
        noteXML = [TBXML nextSiblingNamed:OSMKNoteElementName searchFromElement:noteXML];
    }
    
   
}

@end

//
//  OSMKNSXMLParser.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKNSXMLParser.h"
#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "OSMKUser.h"
#import "OSMKNote.h"
#import "OSMKComment.h"

@interface OSMKNSXMLParser () <NSXMLParserDelegate>

@property (nonatomic, strong) NSXMLParser *xmlParser;

@property (nonatomic, strong) OSMKNode *currentNode;
@property (nonatomic, strong) OSMKWay *currentWay;
@property (nonatomic, strong) OSMKRelation *currentRelation;
@property (nonatomic, strong) OSMKUser *currentUser;
@property (nonatomic, strong) OSMKNote *currentNote;
@property (nonatomic, strong) OSMKComment *currentComment;

@property (nonatomic, strong) NSString *currentElementName;

@property (nonatomic, strong) NSMutableSet *roles;

@property (nonatomic) dispatch_queue_t parseQueue;

@end

@implementation OSMKNSXMLParser

- (id)init {
    if (self = [super init]) {
        NSString *queueString = [NSString stringWithFormat:@"%@-parse",NSStringFromClass([self class])];
        self.parseQueue = dispatch_queue_create([queueString UTF8String], 0);
    }
    return self;
}


- (void)parseXMLData:(NSData *)xmlData
{
    dispatch_async(self.parseQueue, ^{
        self.xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
        [self.xmlParser parse];
    });
}

- (void)parseOSMStream:(NSInputStream *)inputStream
{
    dispatch_async(self.parseQueue, ^{
        self.xmlParser = [[NSXMLParser alloc] initWithStream:inputStream];
        [self.xmlParser parse];
    });
}

- (void)parseOSMUrl:(NSURL *)url
{
    dispatch_async(self.parseQueue, ^{
        self.xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
        [self.xmlParser parse];
    });
}

- (void)parseWithXmlParser:(NSXMLParser *)parser
{
    dispatch_async(self.parseQueue, ^{
        self.xmlParser = parser;
        [self.xmlParser parse];
    });
}

- (void)setXmlParser:(NSXMLParser *)xmlParser
{
    _xmlParser = xmlParser;
    _xmlParser.delegate = self;
}

- (OSMKObject *)currentObject
{
    OSMKObject *object = nil;
    if (self.currentNode) {
        object = self.currentNode;
    }
    else if (self.currentWay) {
        object = self.currentWay;
    }
    else if (self.currentRelation) {
        object = self.currentRelation;
    }
    return object;
}

- (NSString *)string:(NSString *)string1 appendWithString:(NSString *)string2
{
    if (![string1 length]) {
        return string2;
    }
    else {
        return [string1 stringByAppendingString:string2];
    }
}
- (BOOL)currentElementIs:(NSString *)string
{
    return [self.currentElementName isEqualToString:string];
}

#pragma - mark NSXMLParserDelegate Methods

////// Start //////
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    if ([self.delegate respondsToSelector:@selector(parserDidStart:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate parserDidStart:self];
        });
    }
}


////// Found Element //////
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.currentElementName = elementName;
    
    if ([elementName isEqualToString:OSMKNodeElementName]) {
        self.currentNode = [[OSMKNode alloc] initWithAttributesDictionary:attributeDict];
    }
    else if ([elementName isEqualToString:OSMKWayElementName]) {
        self.currentWay = [[OSMKWay alloc] initWithAttributesDictionary:attributeDict];
    }
    else if ([elementName isEqualToString:OSMKRelationElementName]) {
        self.currentRelation = [[OSMKRelation alloc] initWithAttributesDictionary: attributeDict];
    }
    else if ([elementName isEqualToString:OSMKTagElementName]) {
        OSMKObject *currentObject = [self currentObject];
        if (currentObject) {
            NSString *osmKey = attributeDict[@"k"];
            NSString *osmValue = attributeDict[@"v"];
            
            if (!currentObject.tags) {
                currentObject.tags = @{osmKey:osmValue};
            }
            else {
                NSMutableDictionary *mutableDict = [currentObject.tags mutableCopy];
                [mutableDict setObject:osmValue  forKey:osmKey];
                currentObject.tags = [mutableDict copy];
            }
        }
    }
    else if ([elementName isEqualToString:OSMKWayNodeElementName]) {
        if( self.currentWay) {
            NSNumber *ref = @([attributeDict[@"ref"] longLongValue]);
            if (!self.currentWay.nodes) {
                self.currentWay.nodes = @[ref];
            }
            else {
                self.currentWay.nodes = [self.currentWay.nodes arrayByAddingObject:ref];
            }
        }
    }
    else if ([elementName isEqualToString:OSMKRelationMemberElementName]) {
        if (self.currentRelation) {
            OSMKRelationMember *member = [[OSMKRelationMember alloc] initWithAttributesDictionary:attributeDict];
            if (!self.currentRelation.members) {
                self.currentRelation.members = @[member];
            }
            else {
                self.currentRelation.members = [self.currentRelation.members arrayByAddingObject:member];
            }
        }
    }
    else if ([elementName isEqualToString:OSMKUserElementName] && !self.currentNote) {
        self.currentUser = [[OSMKUser alloc] initWithAttributesDictionary:attributeDict];
    }
    else if ([elementName isEqualToString:@"contributor-terms"]) {
        self.currentUser.termsAgreed = [attributeDict[@"agreed"] boolValue];
    }
    else if ([elementName isEqualToString:@"img"]) {
        self.currentUser.imageUrl = [NSURL URLWithString:attributeDict[@"href"]];
    }
    else if ([elementName isEqualToString:OSMKUserRolesElementName]) {
        self.roles = [NSMutableSet set];
    }
    else if (self.roles){
        [self.roles addObject:elementName];
    }
    else if ([elementName isEqualToString:@"changesets"]) {
        self.currentUser.changesetCount = [attributeDict[@"count"] integerValue];
    }
    else if ([elementName isEqualToString:@"traces"]) {
        self.currentUser.traceCount = [attributeDict[@"count"] integerValue];
    }
    else if ([elementName isEqualToString:@"received"]) {
        self.currentUser.receivedBlocks = [attributeDict[@"count"] integerValue];
        self.currentUser.activeReceivedBlocks = [attributeDict[@"active"] integerValue];
    }
    else if ([elementName isEqualToString:@"issued"]) {
        self.currentUser.issuedBlocks = [attributeDict[@"count"] integerValue];
        self.currentUser.activeIssuedBlocks = [attributeDict[@"active"] integerValue];
    }
    else if ([elementName isEqualToString:OSMKNoteElementName])
    {
        self.currentNote = [[OSMKNote alloc] init];
        self.currentNote.coordinate = CLLocationCoordinate2DMake([attributeDict[@"lat"] doubleValue], [attributeDict[@"lon"] doubleValue]);
    }
    else if ([elementName isEqualToString:@"comment"] && self.currentNote)
    {
        self.currentComment = [[OSMKComment alloc] init];
    }
}

////// End Element //////
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:OSMKNodeElementName] && self.currentNode) {
        
        
        if ([self.delegate respondsToSelector:@selector(parser:didFindNode:)]) {
            __block OSMKNode *node = [self.currentNode copy];
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindNode:node];
            });
        }
        
        self.currentNode = nil;
    }
    else if ([elementName isEqualToString:OSMKWayElementName] && self.currentWay) {
        
        if ([self.delegate respondsToSelector:@selector(parser:didFindWay:)]) {
            __block OSMKWay *way = [self.currentWay copy];
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindWay:way];
            });
        }
        
        self.currentWay = nil;
    }
    else if ([elementName isEqualToString:OSMKRelationElementName] && self.currentRelation) {
        
        if ([self.delegate respondsToSelector:@selector(parser:didFindRelation:)]) {
            __block OSMKRelation *relation = [self.currentRelation copy];
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindRelation:relation];
            });
        }
        
        self.currentRelation = nil;
    }
    else if ([elementName isEqualToString:OSMKUserElementName] && self.currentUser) {
        if ([self.delegate respondsToSelector:@selector(parser:didFindUser:)]) {
            __block OSMKUser *user = [self.currentUser copy];
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindUser:user];
            });
        }
        
        self.currentUser = nil;
    }
    else if ([elementName isEqualToString:OSMKUserRolesElementName]) {
        self.currentUser.roles = [self.roles copy];
        self.roles = nil;
    }
    else if ([elementName isEqualToString:OSMKNoteElementName] && self.currentNote)
    {
        if ([self.delegate respondsToSelector:@selector(parser:didFindNote:)]) {
            __block OSMKNote *note = [self.currentNote copy];
            dispatch_async(self.delegateQueue, ^{
                [self.delegate parser:self didFindNote:note];
            });
        }
        
        self.currentNote = nil;
    }
    
    else if ([elementName isEqualToString:@"comment"] && self.currentNote && self.currentComment)
    {
        if (self.currentNote.commentsArray) {
            self.currentNote.commentsArray = [self.currentNote.commentsArray arrayByAddingObject:self.currentComment];
        }
        else {
            self.currentNote.commentsArray = @[self.currentComment];
        }
        
        self.currentComment = nil;
    }
    self.currentElementName = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    //string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([self.currentElementName isEqualToString:@"description"] && self.currentUser) {
        
        self.currentUser.userDescription = [self string:self.currentUser.userDescription appendWithString:string];
        
    }
    else if (self.currentComment)
    {
        if ([self currentElementIs:@"date"]) {
            self.currentComment.date = [[OSMKNote defaultDateFormatter] dateFromString:string];
        }
        else if ([self currentElementIs:@"uid"]) {
            self.currentComment.userId = [string longLongValue];
        }
        else if ([self currentElementIs:@"user"]) {
            self.currentComment.user = [self string:self.currentComment.user appendWithString:string];
        }
        else if ([self currentElementIs:@"action"]) {
            self.currentComment.action = [self string:self.currentComment.action appendWithString:string];
        }
        else if ([self currentElementIs:@"text"]) {
            self.currentComment.text = [self string:self.currentComment.text appendWithString:string];
        }
    }
    else if (self.currentNote) {
        if ([self currentElementIs:@"id"]) {
            self.currentNote.osmId = [string longLongValue];
        }
        else if ([self currentElementIs:@"date_created"]) {
            self.currentNote.dateCreated = [[OSMKNote defaultDateFormatter] dateFromString:string];
        }
        else if ([self currentElementIs:@"date_closed"])
        {
            self.currentNote.dateClosed = [[OSMKNote defaultDateFormatter] dateFromString:string];
        }
        else if ([self currentElementIs:@"status"]) {
            self.currentNote.isOpen = [string isEqualToString:@"open"];
        }
    }
    
}


////// Errors //////
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    if([self.delegate respondsToSelector:@selector(parser:parseErrorOccurred:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate parser:self parseErrorOccurred:parseError];
        });
    }
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    if([self.delegate respondsToSelector:@selector(parser:parseErrorOccurred:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate parser:self parseErrorOccurred:validationError];
        });
    }
}


////// Finish //////
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    if ([self.delegate respondsToSelector:@selector(parserDidFinish:)]) {
        dispatch_async(self.delegateQueue, ^{
            [self.delegate parserDidFinish:self];
        });
    }
}

@end

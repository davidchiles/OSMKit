//
//  OSMKNSXMLParser.m
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKNSXMLParseOperation.h"
#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"
#import "OSMKUser.h"
#import "OSMKNote.h"
#import "OSMKComment.h"



typedef NS_ENUM(NSInteger, OSMKOperationState) {
    OSMKOperationPausedState      = -1,
    OSMKOperationReadyState       = 1,
    OSMKOperationExecutingState   = 2,
    OSMKOperationFinishedState    = 3,
};

static inline BOOL OSMKStateTransitionIsValid(OSMKOperationState fromState, OSMKOperationState toState, BOOL isCancelled) {
    switch (fromState) {
        case OSMKOperationReadyState:
            switch (toState) {
                case OSMKOperationPausedState:
                case OSMKOperationExecutingState:
                    return YES;
                case OSMKOperationFinishedState:
                    return isCancelled;
                default:
                    return NO;
            }
        case OSMKOperationExecutingState:
            switch (toState) {
                case OSMKOperationPausedState:
                case OSMKOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        case OSMKOperationFinishedState:
            return NO;
        case OSMKOperationPausedState:
            return toState == OSMKOperationReadyState;
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            switch (toState) {
                case OSMKOperationPausedState:
                case OSMKOperationReadyState:
                case OSMKOperationExecutingState:
                case OSMKOperationFinishedState:
                    return YES;
                default:
                    return NO;
            }
        }
#pragma clang diagnostic pop
    }
}

static inline NSString * OSMKKeyPathFromOperationState(OSMKOperationState state) {
    switch (state) {
        case OSMKOperationReadyState:
            return @"isReady";
        case OSMKOperationExecutingState:
            return @"isExecuting";
        case OSMKOperationFinishedState:
            return @"isFinished";
        case OSMKOperationPausedState:
            return @"isPaused";
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            return @"state";
#pragma clang diagnostic pop
        }
    }
}

@interface OSMKNSXMLParseOperation () <NSXMLParserDelegate>

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

@property (nonatomic) OSMKOperationState state;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSMutableArray *nodes;
@property (nonatomic, strong) NSMutableArray *ways;
@property (nonatomic, strong) NSMutableArray *relations;
@property (nonatomic, strong) NSMutableArray *notes;
@property (nonatomic, strong) NSMutableArray *users;

@end

@implementation OSMKNSXMLParseOperation

- (id)init {
    if (self = [super init]) {
        NSString *queueString = [NSString stringWithFormat:@"%@-parse",NSStringFromClass([self class])];
        self.parseQueue = dispatch_queue_create([queueString UTF8String], 0);
        self.state = OSMKOperationReadyState;
    }
    return self;
}


- (instancetype)initWithStream:(NSInputStream *)inputStream
{
    if (self = [self init]) {
        self.xmlParser = [[NSXMLParser alloc] initWithStream:inputStream];
    }
    return self;
}
- (instancetype)initWithURL:(NSURL *)url
{
    if (self = [self init]) {
        self.xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    }
    return self;
}
- (instancetype)initWithXMLParser:(NSXMLParser *)parser
{
    if (self = [self init]) {
        self.xmlParser = parser;
    }
    return self;
}

- (BOOL)isExecuting {
    return self.state == OSMKOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == OSMKOperationFinishedState;
}

- (BOOL)isReady {
    return self.state == OSMKOperationReadyState;
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)start {
    self.state = OSMKOperationExecutingState;
    [self main];
    
}

- (void)main {
    if (!self.xmlParser) {
        self.xmlParser = [[NSXMLParser alloc] initWithData:self.data];
    }
    
    [self.xmlParser parse];
}

- (void)setState:(OSMKOperationState)state
{
    if (!OSMKStateTransitionIsValid(self.state, state, [self isCancelled])) {
        return;
    }
    
    NSString *oldStateKey = OSMKKeyPathFromOperationState(self.state);
    NSString *newStateKey = OSMKKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];}

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

#pragma - mark Found Objects

- (void)foundNode:(OSMKNode *)node
{
    if (node) {
        if (!self.nodes) {
            self.nodes = [NSMutableArray new];
        }
        [self.nodes addObject:node];
    }
}

- (void)foundWay:(OSMKWay *)way
{
    if (way) {
        if (!self.ways) {
            self.ways = [NSMutableArray new];
        }
        [self.ways addObject:way];
    }
}

- (void)foundRelation:(OSMKRelation *)relation
{
    if (relation) {
        if (!self.relations) {
            self.relations = [NSMutableArray new];
        }
        [self.relations addObject:relation];
    }
}

- (void)foundNote:(OSMKNote *)note
{
    if (note) {
        if (!self.notes) {
            self.notes = [NSMutableArray new];
        }
        [self.notes addObject:note];
    }
}

- (void)foundUser:(OSMKUser *)user
{
    if (user) {
        if (!self.users) {
            self.users = [NSMutableArray new];
        }
        [self.users addObject:user];
    }
}

#pragma - mark NSXMLParserDelegate Methods

////// Start //////
- (void)parserDidStartDocument:(NSXMLParser *)parser
{

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
        
        [self foundNode:self.currentNode];
        
        self.currentNode = nil;
    }
    else if ([elementName isEqualToString:OSMKWayElementName] && self.currentWay) {
        
        [self foundWay:self.currentWay];
        
        self.currentWay = nil;
    }
    else if ([elementName isEqualToString:OSMKRelationElementName] && self.currentRelation) {
        
        [self foundRelation:self.currentRelation];
        
        self.currentRelation = nil;
    }
    else if ([elementName isEqualToString:OSMKUserElementName] && self.currentUser) {
        
        [self foundUser:self.currentUser];
        
        self.currentUser = nil;
    }
    else if ([elementName isEqualToString:OSMKUserRolesElementName]) {
        self.currentUser.roles = [self.roles copy];
        self.roles = nil;
    }
    else if ([elementName isEqualToString:OSMKNoteElementName] && self.currentNote)
    {
        [self foundNote:self.currentNote];
        
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
    self.error = parseError;
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    self.error = validationError;
}


////// Finish //////
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    dispatch_queue_t queue = self.completionQueue ?: dispatch_get_main_queue();
    if (self.elementsCompletionBlock) {
        dispatch_async(queue, ^{
            self.elementsCompletionBlock(self.nodes,self.ways,self.relations);
        });
    }
    
    if (self.notesCompletionBlock) {
        dispatch_async(queue, ^{
            self.notesCompletionBlock(self.notes);
        });
    }
    
    if (self.usersCompletionBlock) {
        dispatch_async(queue, ^{
            self.usersCompletionBlock(self.users);
        });
    }
    
    
    self.state = OSMKOperationFinishedState;
}

@end

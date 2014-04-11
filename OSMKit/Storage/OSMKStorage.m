//
//  OSMKStorage.m
//  OSMKit
//
//  Created by David Chiles on 4/11/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKStorage.h"
#import "OSMKTBXMLParser.h"

#import "OSMKStorage.h"
#import "OSMKNSJSONSerializationParser.h"

@interface OSMKStorage ()

@property (nonatomic, strong) OSMKXMLParser *xmlParser;
@property (nonatomic, strong) OSMKNSJSONSerializationParser *jsonParser;
@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, strong) dispatch_queue_t storageQueue;
@property (nonatomic, strong) dispatch_queue_t parserDelegateQueue;
@property (nonatomic, strong) dispatch_queue_t delegateQueue;


@end

@implementation OSMKStorage

- (instancetype)initWithdatabaseFilePath:(NSString *)filePath delegate:(id<OSMKStorageDelegateProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (self = [self init]) {
        self.filePath = filePath;
        self.delegate = delegate;
        if(delegateQueue) {
            self.delegateQueue = delegateQueue;
        }
        else {
            NSString *name = [NSString stringWithFormat:@"%@-delegate",NSStringFromClass([self class])];
            self.delegateQueue = dispatch_queue_create([name UTF8String], 0);
        }
        
        NSString * queueString = [NSString stringWithFormat:@"%@-parserQueue",NSStringFromClass([self class])];
        self.parserDelegateQueue = dispatch_queue_create([queueString UTF8String], 0);
        queueString = [NSString stringWithFormat:@"%@-storageQueue",NSStringFromClass([self class])];
        self.storageQueue = dispatch_queue_create([queueString UTF8String], 0);
        
        
    }
    return self;
}

- (void)importXMLData:(NSData *)data
{
    if (!self.xmlParser) {
        self.xmlParser = [[[OSMKStorage defaultXMLParserClass] alloc] initWithDelegate:self delegateQueue:self.parserDelegateQueue];
    }
    [self.xmlParser parseXMLData:data];
}

- (void)importJSONData:(NSData *)data
{
    if (!self.jsonParser) {
        self.jsonParser = [[OSMKNSJSONSerializationParser alloc] initWithDelegate:self delegateQueue:self.parserDelegateQueue];
    }
    [self.jsonParser parseJSONData:data];
}

#pragma - mark OSMKStorageDelegateProtocol

- (void)parserDidStart:(OSMKParser *)parser
{
    
}
- (void)parser:(OSMKParser *)parser didFindNode:(OSMKNode *)node
{
    
}
- (void)parser:(OSMKParser *)parser didFindWay:(OSMKWay *)way
{
    
}
- (void)parser:(OSMKParser *)parser didFindRelation:(OSMKRelation *)relation
{
    
}
- (void)parser:(OSMKParser *)parser didFindNote:(OSMKNote *)note
{
    
}
- (void)parser:(OSMKParser *)parser didFindUser:(OSMKUser *)user
{
    
}

- (void)parserDidFinish:(OSMKParser *)parser
{
    
}

- (void)parser:(OSMKParser *)parser parseErrorOccurred:(NSError *)parseError
{
    
}


#pragma - mark Class Methods

+ (Class)defaultXMLParserClass
{
    return [OSMKTBXMLParser class];
    
}

@end

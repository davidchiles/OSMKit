//
//  OSMKAPIClient.m
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import "OSMKAPIClient.h"

#import "AFNetworking.h"
#import "OSMKRequestSerializer.h"
#import "OSMKBoundingBox.h"
#import "OSMKChangeset.h"
#import "OSMKNode.h"
#import "OSMKWay.h"
#import "OSMKRelation.h"
#import "OSMKRelationMember.h"

#import "DDXMLElement.h"
#import "DDXMLNode.h"
#import "DDXMLDocument.h"
#import "DDXMLElementAdditions.h"
#import "OSMKNote.h"
#import "OSMKComment.h"

NSString *const OSMKBaseURLString = @"https://api.openstreetmap.org/api/0.6/";
NSString *const OSMKTestBaseURLString = @"http://api06.dev.openstreetmap.org/api/0.6/";

static NSString *const OSMKContentType = @"application/osm3s+xml";

@implementation OSMKAPIClient

- (instancetype)init
{
    return [self initWithBaseURL:[NSURL URLWithString:OSMKBaseURLString]];
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    if (self = [super initWithBaseURL:url]) {
        AFXMLParserResponseSerializer * xmlParserResponseSerializer =  [AFXMLParserResponseSerializer serializer];
        NSMutableSet * contentTypes = [xmlParserResponseSerializer.acceptableContentTypes mutableCopy];
        [contentTypes addObject:@"application/osm3s+xml"];
        xmlParserResponseSerializer.acceptableContentTypes = contentTypes;
        self.responseSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[[AFJSONResponseSerializer serializer],xmlParserResponseSerializer]];
    }
    return self;
}

- (instancetype)initWithConsumerKey:(NSString *)consumerKey privateKey:(NSString *)privateKey token:(NSString *)token tokenSecret:(NSString *)tokenSecret
{
    if (self = [self init]) {
        OSMKRequestSerializer *requestSerializer = [[OSMKRequestSerializer alloc] initWithConsumerKey:consumerKey privateKey:privateKey token:token tokenSecret:tokenSecret];
        self.requestSerializer = requestSerializer;
    }
    return self;
}

//////  Download //////

-(void)downloadDataWithSW:(CLLocationCoordinate2D)southWest NE:(CLLocationCoordinate2D)northEast
                  success:(void (^)(NSData * response))success
                  failure:(void (^)(NSError *error))failure
{
    
    OSMKBoundingBox * bbox = [OSMKBoundingBox boundingBoxWithCornersSW:southWest NE:northEast];
    NSString * bboxString = [NSString stringWithFormat:@"%f,%f,%f,%f",bbox.left,bbox.bottom,bbox.right,bbox.top];
    NSDictionary * parametersDictionary = @{@"bbox": bboxString};
    AFHTTPRequestOperation * httpRequestOperation = [self GET:@"map" parameters:parametersDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure)
        {
            failure(error);
        }
    }];
    [httpRequestOperation start];

}

-(void)downloadNotesWithSW:(CLLocationCoordinate2D)southWest NE:(CLLocationCoordinate2D)northEast
                   success:(void (^)(id response))success
                   failure:(void (^)(NSError *error))failure
{
    OSMKBoundingBox * bbox = [OSMKBoundingBox boundingBoxWithCornersSW:southWest NE:northEast];
    NSString * bboxString = [NSString stringWithFormat:@"%f,%f,%f,%f",bbox.left,bbox.bottom,bbox.right,bbox.top];
    NSDictionary * parametersDictionary = @{@"bbox": bboxString};
    AFHTTPRequestOperation * httpRequestOperation = [self GET:@"notes.json" parameters:parametersDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure)
        {
            failure(error);
        }
    }];
    [httpRequestOperation start];
}


////// Upload //////

- (void)openChangeset:(OSMKChangeset *)changeset
              success:(void (^)(int64_t changesetID))success
              failure: (void (^)(NSError * error))failure
{
    DDXMLElement *element = [self osmElement];
    [element addChild:[changeset PUTXML]];
    
    NSData *changesetData = [[element compactXMLString] dataUsingEncoding:NSUTF8StringEncoding];
    
    AFHTTPRequestOperation *request = [self PUT:@"changeset/create" XML:changesetData success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success([[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] longLongValue]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError * error) {
        if (failure) {
            failure(error);
        }
    }];
    [request start];
}

- (void)uploadElement:(OSMKObject *)object
          changesetID:(NSNumber *)changesetID
           completion:(void (^)(OSMKObject *element, id response ,NSError *error))completion
{
    void (^successBlock)(AFHTTPRequestOperation *operation, id response) = ^void(AFHTTPRequestOperation *operation, id response) {
        if (completion) {
            completion(object,response,nil);
        }
    };
    void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *failure) = ^void(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(object,nil,error);
        }
        
    };
    
    NSString *path = nil;
    if ([object isKindOfClass:[OSMKNode class]]) {
        path = @"node";
    }
    else if ([object isKindOfClass:[OSMKWay class]]) {
        path = @"way";
    }
    else if ([object isKindOfClass:[OSMKRelation class]]) {
        path = @"relation";
    }
    
    if ([path length] && object.osmId > 0) {
        path = [path stringByAppendingFormat:@"/%lld",object.osmId];
    }
    else {
        return;
    }
    
    if (object.action == OSMKElementActionNew) {
        path = [path stringByAppendingString:@"/create"];
    }
    
    AFHTTPRequestOperation *request = nil;
    
    switch (object.action) {
        case OSMKElementActionModified:
        case OSMKElementActionNew:
        {
            DDXMLElement *element = [self osmElement];
            [element addChild:[object PUTElementForChangeset:changesetID]];
            request = [self PUT:path XML:[[element compactXMLString] dataUsingEncoding:NSUTF8StringEncoding] success:successBlock failure:failureBlock];
            break;
        }
        case OSMKElementActionDelete:
        {
            DDXMLElement *element = [self osmElement];
            [element addChild:[object DELETEEelementForChangeset:changesetID]];
            request = [self DELETE:path XML:[[element compactXMLString] dataUsingEncoding:NSUTF8StringEncoding] success:successBlock failure:failureBlock];
            break;
        }
            
            
        default:
            if (completion) {
                completion(object,nil,[NSError errorWithDomain:@"" code:101 userInfo:nil]);
            }
            break;
    }
    
}

- (void)uploadElements:(NSArray *)elements
           changesetID:(NSNumber *)changesetID
               success:(void (^)(NSArray * completed))success
               failure:(void (^)(OSMKObject * element, NSError * error))failure
{
    NSMutableArray *successfulElements = [NSMutableArray new];
    
    [elements enumerateObjectsUsingBlock:^(OSMKObject *object, NSUInteger idx, BOOL *stop) {
        [self uploadElement:object changesetID:changesetID completion:^(OSMKObject *element, id response, NSError *error) {
            if (!error) {
                
                if (element.osmId > 0) {
                    element.version = [response intValue];
                }
                else {
                    element.osmId = [response longLongValue];
                }
                
                [successfulElements addObject:element];
                if ([successfulElements count] == [elements count] && success) {
                    success(successfulElements);
                }
            }
            else if(failure){
                *stop = YES;
                failure(element,error);
            }
            
        }];
    }];
}

- (void)uploadChangeset:(OSMKChangeset *)changeset
               success:(void (^)(NSArray *completedNodes, NSArray *completedWays, NSArray *completedRelations))success
               failure:(void (^)(OSMKObject * element, NSError * error))failure;
{
    __block NSArray *completedNodes     = nil;
    __block NSArray *completedWays      = nil;
    __block NSArray *completedRelations = nil;
    
    [self uploadElements:changeset.nodes changesetID:@(changeset.changesetID) success:^(NSArray *completed) {
        completedNodes = completed;
        [self uploadElements:changeset.ways changesetID:@(changeset.changesetID) success:^(NSArray *completed) {
            completedWays = completed;
            [self uploadElements:changeset.relations changesetID:@(changeset.changesetID) success:^(NSArray *completed) {
                completedRelations = completed;
                if (success) {
                    success(completedNodes,completedWays,completedRelations);
                }
            } failure:failure];
        } failure:failure];
    } failure:failure];
    
}

-(void)closeChangeset:(int64_t) changesetNumber
              success:(void (^)(id response))success
              failure:(void (^)(NSError * error))failure
{
    NSString *path = [NSString stringWithFormat:@"changeset/%lld/close",changesetNumber];
    
    AFHTTPRequestOperation *operation = [self PUT:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    [operation start];
    
}

////// Notes //////

-(void)createNewNote:(OSMKNote *)note
             success:(void (^)(NSData * response))success
             failure:(void (^)(NSError *error))failure
{
    OSMKComment *comment = [note.commentsArray firstObject];
    if ([comment.text length]) {
        NSDictionary *parameters = @{@"lat":@(note.latitude),@"lon":@(note.longitude),@"text":comment.text};
        [self POST:@"notes.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                success(responseObject);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
    
}

-(void)createNewComment:(OSMKComment *)comment
               withNote:(OSMKNote *)note
                success:(void (^)(id JSON))success
                failure:(void (^)(NSError *error))failure
{
    if ([comment.text length]) {
        NSString *path = [NSString stringWithFormat:@"notes/%lld/comment.json",note.osmId];
        [self POST:path parameters:@{@"text":comment.text} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (success) {
                success(responseObject);
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
    
    
}

-(void)closeNote:(OSMKNote *)note
     withComment:(OSMKComment *)comment
         success:(void (^)(id JSON))success
         failure:(void (^)(NSError *error))failure
{
    NSDictionary *parameters = nil;
    if ([comment.text length]) {
        parameters = @{@"text":comment.text};
    }
    
    NSString *path = [NSString stringWithFormat:@"notes/%lld/close.json",note.osmId];
    
    [self POST:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

-(void)reopenNote:(OSMKNote *)note
      withComment:(OSMKComment *)comment
          success:(void (^)(NSData * response))success
          failure:(void (^)(NSError *error))failure
{
    NSDictionary *parameters = nil;
    if ([comment.text length]) {
        parameters = @{@"text":comment.text};
    }
    
    NSString *path = [NSString stringWithFormat:@"notes/%lld/reopen.json",note.osmId];
    
    [self POST:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


////////// User //////////////
- (void)fetchCurrentUserWithComletion:(void (^)(id response,NSError *error))completionBlock;
{
    [self GET:@"user/details" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completionBlock) {
            completionBlock(responseObject,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completionBlock) {
            completionBlock(nil,error);
        }
    }];
}

#pragma - mark XML Utility Methods

- (DDXMLElement *)osmElement
{
    DDXMLNode *osmVersion = [DDXMLNode elementWithName:@"version" stringValue:@"0.6"];
    DDXMLNode *osmGenerator = [DDXMLNode elementWithName:@"generator" stringValue:@"OSMKit"];
    DDXMLElement *osmElement = [DDXMLElement elementWithName:@"osm" children:nil attributes:@[osmVersion,osmGenerator]];
    
    DDXMLNode *version = [DDXMLNode elementWithName:@"version" stringValue:@"1.0"];
    DDXMLNode *encoding = [DDXMLNode elementWithName:@"encoding" stringValue:@"UTF-8"];
    DDXMLElement *element = [DDXMLElement elementWithName:@"xml" children:@[osmElement] attributes:@[version,encoding]];

    return element;
}

#pragma - mark HTTP mehtods

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString XML:(NSData *)xmlData success:(void (^)(AFHTTPRequestOperation *, id response))success failure:(void (^)(AFHTTPRequestOperation *, NSError *failure))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    request.HTTPBody = xmlData;
    [request setValue:OSMKContentType forHTTPHeaderField:@"Content-Type"];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (AFHTTPRequestOperation *)DELETE:(NSString *)URLString XML:(NSData *)xmlData success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"DELETE" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:nil error:nil];
    request.HTTPBody = xmlData;
    [request setValue:OSMKContentType forHTTPHeaderField:@"Content-Type"];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self.operationQueue addOperation:operation];
    
    return operation;
}

@end

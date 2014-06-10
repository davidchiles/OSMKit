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
    [element addChild:[self PUTchangesetXML:changeset]];
    
    NSData *changesetData = [[element compactXMLString] dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    [self.requestSerializer requestWithMethod:@"PUT" URLString:@"changeset/create" parameters:nil error:&error];
    
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

-(void)uploadElements:(OSMKChangeset *)changeset
              success:(void (^)(NSArray * elements))success
              failure:(void (^)(OSMKObject * element, NSError * error))failure
{
    
}

-(void)closeChangeset:(int64_t) changesetNumber
              success:(void (^)(id response))success
              failure:(void (^)(NSError * error))failure
{
    
}

////// Notes //////

-(void)createNewNote:(OSMKNote *)note
             success:(void (^)(NSData * response))success
             failure:(void (^)(NSError *error))failure
{
    
}

-(void)createNewComment:(OSMKComment *)comment
               withNote:(OSMKNote *)note
                success:(void (^)(id JSON))success
                failure:(void (^)(NSError *error))failure
{
    
}

-(void)closeNote:(OSMKNote *)note
     withComment:(NSString *)comment
         success:(void (^)(id JSON))success
         failure:(void (^)(NSError *error))failure
{
    
}

-(void)reopenNote:(OSMKNote *)note
          success:(void (^)(NSData * response))success
          failure:(void (^)(NSError *error))failure
{
    
}


////////// User //////////////
- (void)fetchCurrentUserWithComletion:(void (^)(BOOL success,NSError *error))completionBlock
{
    
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

@end

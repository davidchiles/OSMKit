//
//  OSMKAPIClient.h
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AFNetworking.h"

@class OSMKChangeset;
@class OSMKObject;
@class OSMKNote;
@class OSMKComment;
@class DDXMLElement;

extern NSString *const OSMKBaseURLString;
extern NSString *const OSMKTestBaseURLString;

@interface OSMKAPIClient : AFHTTPRequestOperationManager

- (instancetype)initWithConsumerKey:(NSString *)consumerKey privateKey:(NSString *)privateKey token:(NSString *)token tokenSecret:(NSString *)tokenSecret;

////// Download //////

-(void)downloadDataWithSW:(CLLocationCoordinate2D)southWest NE:(CLLocationCoordinate2D)northEast
                  success:(void (^)(NSXMLParser* xmlParser))success
                  failure:(void (^)(NSError *error))failure;

-(void)downloadNotesWithSW:(CLLocationCoordinate2D)southWest NE:(CLLocationCoordinate2D)northEast
                   success:(void (^)(id response))success
                   failure:(void (^)(NSError *error))failure;


////// Upload //////

- (void)openChangeset:(OSMKChangeset *)changeset
              success:(void (^)(int64_t changesetID))success
              failure: (void (^)(NSError * error))failure;

-(void)uploadElements:(OSMKChangeset *)changeset
              success:(void (^)(NSArray * elements))success
              failure:(void (^)(OSMKObject * element, NSError * error))failure;

-(void)closeChangeset:(int64_t) changesetNumber
              success:(void (^)(id response))success
              failure:(void (^)(NSError * error))failure;

////// Notes //////

-(void)createNewNote:(OSMKNote *)note
             success:(void (^)(NSData * response))success
             failure:(void (^)(NSError *error))failure;

-(void)createNewComment:(OSMKComment *)comment
               withNote:(OSMKNote *)note
                success:(void (^)(id JSON))success
                failure:(void (^)(NSError *error))failure;

-(void)closeNote:(OSMKNote *)note
     withComment:(NSString *)comment
         success:(void (^)(id JSON))success
         failure:(void (^)(NSError *error))failure;

-(void)reopenNote:(OSMKNote *)note
          success:(void (^)(NSData * response))success
          failure:(void (^)(NSError *error))failure;


////////// User //////////////
- (void)fetchCurrentUserWithComletion:(void (^)(BOOL success,NSError *error))completionBlock;

////// XML //////
- (DDXMLElement *)PUTchangesetXML:(OSMKChangeset *)changeset;

@end

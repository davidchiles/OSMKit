//
//  OSMKAPITests.m
//  OSMKit
//
//  Created by David Chiles on 6/9/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSMKAPIClient.h"
#import <CoreLocation/CoreLocation.h>
#import "OSMKChangeset.h"
#import "DDXML.h"

@interface OSMKAPITests : XCTestCase

@property (nonatomic, strong) OSMKAPIClient *apiClient;

@end

@implementation OSMKAPITests

- (void)setUp
{
    [super setUp];
    self.apiClient = [[OSMKAPIClient alloc] init];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.apiClient = nil;
}
/*
- (void)testDownloadData
{
    TRVSMonitor *monitor = [[TRVSMonitor alloc] init];
    CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(37.87128, -122.26965);
    CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(37.87282, -122.26688);
    
    __block NSError *error = nil;
    __block NSXMLParser *xmlParser = nil;
    
    [self.apiClient downloadDataWithSW:southWest NE:northEast success:^(NSXMLParser *parser) {
        
        xmlParser = parser;
        [monitor signal];
        
    } failure:^(NSError *error) {
        
        error = error;
        [monitor signal];
    }];
    
    [monitor waitWithTimeout:100.0];
    
    XCTAssertNotNil(xmlParser, @"Could not download data");
    XCTAssertNil(error, @"Found Error %@",error);
}

- (void)testDownloadNotes
{
    TRVSMonitor *monitor = [[TRVSMonitor alloc] init];
    CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(37.7668, -122.4374);
    CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(37.8132, -122.3485);
    
    
    __block id responseObject = nil;
    __block NSError *responseError = nil;
    [self.apiClient downloadNotesWithSW:southWest NE:northEast success:^(id response) {
        responseObject = response;
        [monitor signal];
    } failure:^(NSError *error) {
        responseError = error;
        [monitor signal];
    }];
    
    [monitor waitWithTimeout:100.0];
    
    XCTAssertNil(responseError, @"Error fetching notes %@",responseError);
    XCTAssertNotNil(responseObject, @"Could not find data");
}

- (void)testChangesetXML
{
    OSMKChangeset *changeset = [[OSMKChangeset alloc] initWithTags:@{@"created_by":@"me",@"comment":@"hello bob ēį"}];
    DDXMLElement *element = [changeset PUTXML];
    NSString *string = [element XMLStringWithOptions:DDXMLNodeCompactEmptyElement];
    
    XCTAssert([string length] > 0, @"No element created");
}
 */

@end

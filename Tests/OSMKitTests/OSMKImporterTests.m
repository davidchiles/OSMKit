//
//  OSMKImporterTests.m
//  OSMKit
//
//  Created by David Chiles on 1/13/15.
//  Copyright (c) 2015 davidchiles. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OSMKTestData.h"
#import "OSMKImporter.h"

@interface OSMKImporterTests : XCTestCase

@property (nonatomic, strong) OSMKTestData *testData;
@property (nonatomic, strong) dispatch_queue_t completionQueue;

@property (nonatomic, strong) NSString *documentsPath;

@end

@implementation OSMKImporterTests

- (void)setUp {
    [super setUp];
    NSString *queueLabel = [NSString stringWithFormat:@"%@-completion",NSStringFromClass([self class])];
    self.completionQueue = dispatch_queue_create([queueLabel UTF8String], 0);
    self.testData = [[OSMKTestData alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.documentsPath = [paths firstObject];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testImport {
    
    __block int count = 0;
    [self.testData enumerateXMLDataSources:^(OSMKTestObject *testObject, BOOL *stop) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"import-%@",testObject]];
        OSMKImporter *importer = [[OSMKImporter alloc] init];
        NSString *path = [self.documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"db%d.sqlite",count]];
        [importer setupDatbaseWithPath:path overwrite:YES];
        [importer importXMLData:testObject.data
                     completion:^{
                         NSLog(@"all done");
                         [expectation fulfill];
                     }
                completionQueue:self.completionQueue];
        count++
        ;
    }];
    
    
    
    [self waitForExpectationsWithTimeout:1000000 handler:^(NSError *error) {
        NSLog(@"Timeout Error: %@",error);
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        [self testImport];
    }];
}

@end

//
//  OSMKImporter.h
//  Pods
//
//  Created by David Chiles on 1/13/15.
//
//

#import <Foundation/Foundation.h>

@interface OSMKImporter : NSObject

- (BOOL)setupDatbaseWithPath:(NSString *)path overwrite:(BOOL)overwrite;

- (void)importXMLData:(NSData *)xmlData completion:(void (^)(void))completion completionQueue:(dispatch_queue_t)completionQueue;

@end

//
//  OSMKComment.h
//  OSMKit
//
//  Created by David Chiles on 4/10/14.
//  Copyright (c) 2014 davidchiles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSMKComment : NSObject <NSCopying>

@property (nonatomic) int64_t noteId;
@property (nonatomic) int64_t userId;
@property (nonatomic,strong) NSString *user;
@property (nonatomic,strong) NSDate *date;
@property (nonatomic,strong) NSString *text;
@property (nonatomic,strong) NSString *action;

- (id)initWithDictionary:(NSDictionary *)dictionary;

+ (instancetype)commentWithDictionary:(NSDictionary *)dictionary;

@end

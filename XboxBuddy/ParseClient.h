//
//  ParseClient.h
//  XboxBuddy
//
//  Created by Amber Roy on 2/23/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFQuery.h>
#import "Comment.h"
#import "Like.h"

extern NSString * const ParseClientDidInitNotification;

@interface ParseClient : NSObject

+ (ParseClient *) instance;
+ (void) resetInstance;

+(BOOL)isOfflineMode;
+(void)setIsOfflineMode:(BOOL)isOfflineMode;

- (void) initInstance:(Profile *)userProfile withProfiles:(NSArray *)friendProfiles;

- (NSArray *) commentsForAchievement:(Achievement *)achievement;
- (NSArray *) likesForAchievement:(Achievement *)achievement;

- (void) saveComment:(Comment *)comment;
- (void) saveLike:(Like *)like;

+ (void)sendPushNotification:(NSString *)type withAchievement:(Achievement *)achievement;

@end

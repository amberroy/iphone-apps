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
#import "Invitation.h"

extern NSString * const ParseClientDidInitNotification;

@interface ParseClient : NSObject

+ (ParseClient *) instance;
+ (void) resetInstance;

+(BOOL)isOfflineMode;
+(void)setIsOfflineMode:(BOOL)isOfflineMode;

- (void) initInstance:(Profile *)userProfile withProfiles:(NSArray *)friendProfiles;

- (NSMutableArray *) commentsForAchievement:(Achievement *)achievement;
- (NSMutableArray *) likesForAchievement:(Achievement *)achievement;
- (Invitation *) invitationForGamertag:(NSString *)gamertag;
- (User *) userForGamertag:(NSString *)gamertag;

- (void) registerInstallation;
- (void) saveComment:(Comment *)comment;
- (void) deleteComment:(Comment *)comment;
- (void) saveLike:(Like *)like;
- (void) deleteLike:(Like *)like;
- (void) saveInvitation:(Invitation *)invitation;
- (void) deleteInvitation:(Invitation *)invitation;

+ (void)sendPushNotification:(NSString *)action withAchievement:(Achievement *)achievement;

@end

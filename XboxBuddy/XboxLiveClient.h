//
//  XboxLiveAPI.h
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Achievement.h"
#import "Profile.h"
#import "Game.h"

extern NSString *const XboxLiveClientDidInitNotification;

@class XboxLiveClient;

@interface XboxLiveClient : NSObject <UIAlertViewDelegate>


+(XboxLiveClient *) instance;
+(NSArray *)gamertagsForTesting;

+(NSString *)filePathForImageUrl:(NSString *)url;

-(NSArray *) achievements;
-(NSArray *) achievementsWithGamertag:(NSString *)gamertag;
-(Achievement *) achievementWithGamertag:(NSString *)gamertag
                            withGameName:(NSString *)gameName
                     withAchievementName:(NSString *)achievementName;

-(Profile *) userProfile;
-(NSArray *) friendProfiles;
-(Profile *) friendProfileWithGamertag:(NSString *)gamertag;

-(void)initInstance;
+(void)resetInstance;

+(BOOL)isOfflineMode;
+(void)setIsOfflineMode:(BOOL)isOfflineMode;

+(BOOL)isDemoMode;
+(void)setIsDemoMode:(BOOL)isDemoMode;


@end

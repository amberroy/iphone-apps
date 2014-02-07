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

@class XboxLiveClient;

@interface XboxLiveClient : NSObject <UIAlertViewDelegate>

+(XboxLiveClient *) instance;
+(NSArray *)gamertagsForTesting;

+(NSString *)filePathForUrl:(NSString *)url;
+(NSString *)filePathForUrl:(NSString *)url withExtension:(NSString *)extension;

// TODO: move this to util
+(UIImage *)createRoundedUserWithImage:(UIImage *)image;


-(NSArray *) achievements;
-(NSArray *) achievementsWithGamertag:(NSString *)gamertag;

-(Profile *) userProfile;
-(NSArray *) friendProfiles;
-(Profile *) friendProfileWithGamertag:(NSString *)gamertag;

-(void)initWithGamertag:(NSString *)userGamertag
             completion:(void (^)(NSString *errorDescription))completion;

// Defaults to NO.  Enable to use saved results from previous API calls.
@property BOOL isOfflineMode;

@end

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

+(NSString *)filePathForImageUrl:(NSString *)url;

-(NSArray *) achievements;
-(NSArray *) achievementsWithGamertag:(NSString *)gamertag;

-(Profile *) userProfile;
-(NSArray *) friendProfiles;
-(Profile *) friendProfileWithGamertag:(NSString *)gamertag;

-(void)initInstance;
+(void)resetInstance;

@end

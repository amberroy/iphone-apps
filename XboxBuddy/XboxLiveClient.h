//
//  XboxLiveAPI.h
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Achievement.h"

@class XboxLiveClient;

@interface XboxLiveClient : NSObject

+(XboxLiveClient *) instance;

-(Achievement *) achievements;
-(NSArray *) achievementsWithGamertag:(NSString *)gamertag;

// TODO
//-(Profile *) userProfile;
//-(Profile *) friendProfiles;
//-(NSArray *) friendProfileWithGamertag:(NSString *)gamertag;

-(void)initWithGamertag:(NSString *)userGamertag
             completion:(void (^)(NSString *errorDescription))completion;

-(void)initWithGamertag:(NSString *)userGamertag
           useSavedData:(BOOL)useSavedData
             completion:(void (^)(NSString *errorDescription))completion;

@end

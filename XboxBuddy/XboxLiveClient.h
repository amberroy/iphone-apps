//
//  XboxLiveAPI.h
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XboxLiveClient;

@interface XboxLiveClient : NSObject

@property NSString *userGamertag;
@property NSDictionary *userProfile;
@property NSArray *userFriends;

@property NSArray *friendProfiles;
@property NSArray *achievements;

+(XboxLiveClient*)instance;

-(void)initWithGamertag:(NSString *)userGamertag
             completion:(void (^)(NSString *errorDescription))completion;

@end

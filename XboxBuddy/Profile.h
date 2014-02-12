//
//  Profile.h
//  XboxBuddy
//
//  Created by Amber Roy on 2/2/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Profile : NSObject

// Player info.
@property NSString *gamertag;
@property NSInteger gamerscore;
@property NSString *gamerpicImageUrl;
@property NSString *onlineStatus;
@property NSString *avatarImageUrl;

// Game info for most recently earned achievement.
@property NSString *gameName;
@property NSString *gameImageUrl;
@property NSInteger gamePointsPossible;
@property NSInteger gamePointsEarned;

+(NSArray *)profilesWithArray:(NSArray *)array;
- (Profile *)initWithDictionary:(NSDictionary *)dict;

@end

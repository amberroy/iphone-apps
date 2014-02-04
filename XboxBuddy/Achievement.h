//
//  Achievement.h
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Achievement : NSObject

// Achievement info.
@property NSString *name;
@property NSString *description;
@property NSString *imageUrl;
@property NSDate *earnedOn;
@property NSInteger points;

// Game info.
@property NSString *gameName;
@property NSString *gameImageUrl;
@property NSInteger gameAchievementsPossible;
@property NSInteger gamePointsPossible;

// Player progress on this game.
@property NSInteger gameAchievementsEarned;
@property NSInteger gamePointsEarned;
@property NSDate *gameLastPlayed;

// Player info.
@property NSString *gamertag;
@property NSInteger gamerscore;
@property NSString *gamerImageUrl;

// TODO: move this to util file
+(NSString *)timeAgoWithDate:(NSDate *)date;

+(NSArray *)achievementsWithArray:(NSArray *)array;


@end

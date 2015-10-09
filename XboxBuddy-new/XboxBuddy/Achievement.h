//
//  Achievement.h
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Game.h"

@interface Achievement : NSObject

// Achievement info.
@property NSString *name;
@property NSString *detail;
@property NSString *imageUrl;
@property NSDate *earnedOn;
@property NSInteger points;
@property NSString *achievementID;

// Player info.
@property NSString *gamertag;
@property NSInteger gamerscore;
@property NSString *gamerpicImageUrl;
@property NSString *avatarImageUrl;

// Game info.
@property Game *game;

// TODO: move this to util file
+(NSString *)timeAgoWithDate:(NSDate *)date;
+(UIImage *)createRoundedUserWithImage:(UIImage *)image;

+(NSArray *)achievementsWithArray:(NSArray *)array;

- (Achievement *)initWithDictionary:(NSDictionary *)dict;

@end

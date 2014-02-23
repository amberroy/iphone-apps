//
//  Game.h
//  XboxBuddy
//
//  Created by Amber Roy on 2/23/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Game : NSObject

@property NSString *name;
@property NSInteger pointsPossible;
@property NSInteger pointsEarned;
@property NSInteger achievementsPossible;
@property NSInteger achievementsEarned;
@property NSInteger progress;
@property NSString *imageUrl;
@property NSDate *lastPlayed;

- (Game *)initWithDictionary:(NSDictionary *)dict;

@end

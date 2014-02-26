//
//  Game.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/23/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Game.h"

@implementation Game

- (Game *)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        self.name = dict[@"Name"];
        self.pointsPossible = [dict[@"PossibleGamerscore"] integerValue];
        self.achievementsPossible = [dict[@"PossibleAchievements"] integerValue];
        self.imageUrl = dict[@"BoxArt"][@"Large"];
        double lastPlayedSeconds = [dict[@"Progress"][@"LastPlayed-UNIX"] doubleValue];
        self.lastPlayed = [NSDate dateWithTimeIntervalSince1970:lastPlayedSeconds];
        self.gameID = dict[@"ID"];
        
        // Handle inconsistent naming of dict keys.
        NSString *scoreKey = (dict[@"Progress"][@"Score"]) ? @"Score" : @"Gamerscore";
        self.pointsEarned = [dict[@"Progress"][scoreKey] integerValue];
        NSString *achievementsKey = (dict[@"Progress"][@"Achievements"]) ? @"Achievements" : @"EarnedAchievements";
        self.achievementsEarned = [dict[@"Progress"][achievementsKey] integerValue];
        
        self.progress = round(((float)self.achievementsEarned / self.achievementsPossible) * 100);
        
    }
    return self;
}

@end

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
        self.pointsEarned = [dict[@"Progress"][@"Score"] integerValue];
        self.achievementsPossible = [dict[@"PossibleAchievements"] integerValue];
        self.achievementsEarned = [dict[@"Progress"][@"Achievements"] integerValue];
        self.imageUrl = dict[@"BoxArt"][@"Large"];
        self.progress = round((float)self.achievementsEarned / self.achievementsPossible);
        double lastPlayedSeconds = [dict[@"Progress"][@"LastPlayed-UNIX"] doubleValue];
        self.lastPlayed = [NSDate dateWithTimeIntervalSince1970:lastPlayedSeconds];
    }
    return self;
}

@end

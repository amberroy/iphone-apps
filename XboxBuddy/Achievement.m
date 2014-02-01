//
//  Achievement.m
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Achievement.h"

@implementation Achievement

+(NSArray *)achievementsWithArray:(NSArray *)array
{
    NSMutableArray *achievementObjects = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (NSDictionary *achievementDict in array) {
        Achievement *object = [[Achievement alloc] initWithDictionary:achievementDict];
        [achievementObjects addObject:object];
    }
    return achievementObjects;
}

- (Achievement *)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.name = dict[@"Achievement"][@"Name"];
        self.gamertag = dict[@"Achievement"][@"Gamertag"];
        self.imageUrl = dict[@"Achievement"][@"UnlockedTitleUrl"];
       
        double earnedOn = [dict[@"Achievement"][@"EarnedOn-UNIX"] doubleValue];
        self.earnedOn = [NSDate dateWithTimeIntervalSince1970:earnedOn];
        self.points = [dict[@"Achievement"][@"Score"] integerValue];
        
        self.gameName = dict[@"Game"][@"Name"];
        self.gameImageUrl = dict[@"Game"][@"BoxArt"][@"Small"];
        self.gameAchievementsPossible = [dict[@"Game"][@"PossibleAchievements"] integerValue];
        self.gamePointsPossible = [dict[@"Game"][@"PossibleGamerscore"] integerValue];
        
        self.gameAchievementsEarned = [dict[@"Game"][@"Progress"][@"EarnedAchievements"] integerValue];
        self.gamePointsEarned = [dict[@"Game"][@"Progress"][@"Gamerscore"] integerValue];
        double lastPlayed = [dict[@"Game"][@"Progress"][@"LastPlayed-UNIX"] doubleValue];
        self.gameLastPlayed = [NSDate dateWithTimeIntervalSince1970:lastPlayed];
        
        self.gamertag = dict[@"Player"][@"Gamertag"];
        self.gamerscore = [dict[@"Player"][@"Gamerscore"] integerValue];
        self.gamerImageUrl = dict[@"Player"][@"Avatar"][@"Body"];
    }
    return self;
}

@end

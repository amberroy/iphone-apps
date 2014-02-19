//
//  Profile.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/2/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Profile.h"

@implementation Profile

+(NSArray *)profilesWithArray:(NSArray *)array
{
    NSMutableArray *profileObjects = [[NSMutableArray alloc] initWithCapacity:[array count]];
    for (NSDictionary *achievementDict in array) {
        Profile *object = [[Profile alloc] initWithDictionary:achievementDict];
        [profileObjects addObject:object];
    }
    return profileObjects;
}

- (Profile *)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.gamertag = dict[@"Player"][@"Gamertag"];
        self.gamerscore = [dict[@"Player"][@"Gamerscore"] integerValue];
        self.gamerpicImageUrl = dict[@"Player"][@"Avatar"][@"Gamerpic"][@"Large"];
        self.avatarImageUrl = dict[@"Player"][@"Avatar"][@"Body"];
        
        if (dict[@"LastGame"] != [NSNull null]) {
            self.gameName = dict[@"LastGame"][@"Name"];
            self.gamePointsPossible = [dict[@"LastGame"][@"PossibleGamerscore"] integerValue];
            self.gamePointsEarned = [dict[@"LastGame"][@"Progress"][@"Score"] integerValue];
            self.gameAchievementsPossible = [dict[@"LastGame"][@"PossibleAchievements"] integerValue];
            self.gameAchievementsEarned = [dict[@"LastGame"][@"Progress"][@"Achievements"] integerValue];
            self.gameImageUrl = dict[@"LastGame"][@"BoxArt"][@"Large"];
            self.gameProgress = round((float)self.gameAchievementsEarned / self.gameAchievementsPossible);
            double lastPlayedSeconds = [dict[@"LastGame"][@"Progress"][@"LastPlayed-UNIX"] doubleValue];
            self.lastPlayed = [NSDate dateWithTimeIntervalSince1970:lastPlayedSeconds];
        }
    }
    
    return self;
}

@end

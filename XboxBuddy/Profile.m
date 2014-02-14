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
        self.gamertag = dict[@"gamertag"];
        self.gamerscore = [dict[@"gamerscore"] integerValue];
        self.gamerpicImageUrl = dict[@"avatar"][@"large"];
        self.lastSeen = dict[@"presence"];
        self.isOnline = [dict[@"online"] boolValue];
        self.avatarImageUrl = dict[@"avatar"][@"full"];
        
        self.name = dict[@"name"];
        self.motto = dict[@"motto"];
        self.location = dict[@"location"];
        self.biography = dict[@"biography"];
        self.reputation = [dict[@"reputation"] integerValue];
        self.tier = dict[@"tier"];
        
        if (dict[@"achievement"] != [NSNull null]) {
           self.gameName = dict[@"achievement"][@"game"][@"title"];
           self.gamePointsPossible = [dict[@"achievement"][@"game"][@"gamerscore"][@"total"] integerValue];
           self.gamePointsEarned = [dict[@"achievement"][@"game"][@"gamerscore"][@"current"] integerValue];
           self.gameAchievementsPossible = [dict[@"achievement"][@"game"][@"achievements"][@"total"] integerValue];
           self.gameAchievementsEarned = [dict[@"achievement"][@"game"][@"achievements"][@"current"] integerValue];
           self.gameProgress = [dict[@"achievement"][@"game"][@"progress"] integerValue];
           self.gameImageUrl = dict[@"achievement"][@"game"][@"artwork"][@"large"];
        }
    }
    
    return self;
}

@end

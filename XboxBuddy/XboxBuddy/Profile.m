//
//  Profile.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/2/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Profile.h"
#import "Game.h"

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
        
        if (dict[@"RecentGames"] != [NSNull null]) {
            NSMutableArray *games = [[NSMutableArray alloc] init];
            for (NSDictionary *game in dict[@"RecentGames"]) {
                Game *gameObj = [[Game alloc] initWithDictionary:game];
                [games addObject:gameObj];
            }
            self.recentGames = games;
        }

    }
    
    return self;
}

@end

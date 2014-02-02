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
        self.gamerImageUrl = dict[@"Player"][@"Avatar"][@"Body"];
        self.onlineStatus = dict[@"Player"][@"Status"][@"Online_Status"];
    }
    
    return self;
}

@end

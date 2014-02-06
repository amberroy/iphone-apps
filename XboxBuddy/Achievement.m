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
        if ([dict[@"Achievement"][@"Name"] isEqualToString:@""]) {
            self.name = @"Secret Achievement";
            self.description = @"This is a secret achievement. Unlock it to find out more about it.";
        } else {
            self.name = dict[@"Achievement"][@"Name"];
            self.description = dict[@"Achievement"][@"Description"];
        }
        
        self.imageUrl = dict[@"Achievement"][@"UnlockedTileUrl"];
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

// TODO: move this to util file
+(NSString *)timeAgoWithDate:(NSDate *)date {

    double timeAgoInSeconds = (double)abs([date timeIntervalSinceNow]);

    if (timeAgoInSeconds == 0) {
        return @"Just Now";
    } else if (timeAgoInSeconds < 60) {
        return [NSString stringWithFormat:@"%.0f seconds ago", timeAgoInSeconds];
    } else if (timeAgoInSeconds < 3600) {
        return [NSString stringWithFormat:@"%.0f minutes ago", floor(timeAgoInSeconds/60)];
    } else if (timeAgoInSeconds < 86400) {
        return [NSString stringWithFormat:@"%.0f hours ago", floor(timeAgoInSeconds/3600)];
    } else if (timeAgoInSeconds < 86400 * 7) {
        return [NSString stringWithFormat:@"%.0f days ago", floor(timeAgoInSeconds/86400)];
    } else {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd/yy"];
        return [dateFormat stringFromDate:date];
    }
}


@end

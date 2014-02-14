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
        self.name = dict[@"achievement"][@"title"];
        self.detail = dict[@"achievement"][@"description"];
        
        self.imageUrl = dict[@"achievement"][@"artwork"][@"unlocked"];
        double earnedOn = [dict[@"achievement"][@"unlockdate"] doubleValue];
        self.earnedOn = [NSDate dateWithTimeIntervalSince1970:earnedOn];
        self.points = [dict[@"achievement"][@"gamerscore"] integerValue];
        
        self.gameName = dict[@"game"][@"title"];
        self.gameAchievementsPossible = [dict[@"game"][@"achievements"][@"total"] integerValue];
        self.gamePointsPossible = [dict[@"game"][@"gamerscore"][@"total"] integerValue];
        
        self.gameAchievementsEarned = [dict[@"game"][@"achievements"][@"current"] integerValue];
        self.gamePointsEarned = [dict[@"game"][@"gamerscore"][@"current"] integerValue];
        double lastPlayed = [dict[@"game"][@"lastplayed"] doubleValue];
        self.gameLastPlayed = [NSDate dateWithTimeIntervalSince1970:lastPlayed];
        self.gameImageUrl = dict[@"game"][@"artwork"][@"large"];
        
        self.gamertag = dict[@"player"][@"gamertag"];
        self.gamerscore = [dict[@"player"][@"gamerscore"] integerValue];
        self.gamerpicImageUrl = dict[@"player"][@"avatar"][@"large"];
        self.avatarImageUrl = dict[@"player"][@"avatar"][@"full"];
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

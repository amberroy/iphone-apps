//
//  Achievement.m
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Achievement.h"
#import "XboxLiveClient.h"

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
            self.detail = @"Unlock it to find out more about it.";
        } else {
            self.name = dict[@"Achievement"][@"Name"];
            self.detail = dict[@"Achievement"][@"Description"];
        }
        
        self.imageUrl = dict[@"Achievement"][@"UnlockedTileUrl"];
        if (![self.imageUrl isKindOfClass:[NSString class]]) {
            self.imageUrl = dict[@"Achievement"][@"TileUrl"];
        }
        double earnedOn = [dict[@"Achievement"][@"EarnedOn-UNIX"] doubleValue];
        self.earnedOn = [NSDate dateWithTimeIntervalSince1970:earnedOn];
        self.points = [dict[@"Achievement"][@"Score"] integerValue];
        
        self.gameName = dict[@"Game"][@"Name"];
        self.gameImageUrl = dict[@"Game"][@"BoxArt"][@"Large"];
        self.gameAchievementsPossible = [dict[@"Game"][@"PossibleAchievements"] integerValue];
        self.gamePointsPossible = [dict[@"Game"][@"PossibleGamerscore"] integerValue];
        
        self.gameAchievementsEarned = [dict[@"Game"][@"Progress"][@"Achievements"] integerValue];
        self.gamePointsEarned = [dict[@"Game"][@"Progress"][@"Score"] integerValue];
        double lastPlayed = [dict[@"Game"][@"Progress"][@"LastPlayed-UNIX"] doubleValue];
        self.gameLastPlayed = [NSDate dateWithTimeIntervalSince1970:lastPlayed];
        double progress = (float)self.gameAchievementsEarned / self.gameAchievementsPossible * 100;
        self.gameProgress = round(progress);
        
        self.gamertag = dict[@"Player"][@"Gamertag"];
        self.gamerscore = [dict[@"Player"][@"Gamerscore"] integerValue];
        self.gamerpicImageUrl = dict[@"Player"][@"Avatar"][@"Gamerpic"][@"Large"];
        self.avatarImageUrl = dict[@"Player"][@"Avatar"][@"Body"];
        
    }
    return self;
}


// TODO: move this to util file
+(NSString *)timeAgoWithDate:(NSDate *)date {

    double timeAgoInSeconds = (double)abs([date timeIntervalSinceNow]);

    if (timeAgoInSeconds == 0) {
        return @"Just Now";
    } else if (timeAgoInSeconds < 60) {
        return [NSString stringWithFormat:@"%.0fs ago", timeAgoInSeconds];
    } else if (timeAgoInSeconds < 3600) {
        return [NSString stringWithFormat:@"%.0fm ago", floor(timeAgoInSeconds/60)];
    } else if (timeAgoInSeconds < 86400) {
        return [NSString stringWithFormat:@"%.0fh ago", floor(timeAgoInSeconds/3600)];
    } else if (timeAgoInSeconds < 86400 * 7) {
        return [NSString stringWithFormat:@"%.0fd ago", floor(timeAgoInSeconds/86400)];
    } else {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd/yy"];
        return [dateFormat stringFromDate:date];
    }
}

// TODO: Move to util file
+(UIImage *)createRoundedUserWithImage:(UIImage *)image {
    CGSize imageSize = image.size;
    CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:imageRect];
    [path addClip];
    [image drawInRect:imageRect];
    
    // Uncomment for image outline
    /*
     CGContextRef ctx = UIGraphicsGetCurrentContext();
     CGContextSetStrokeColorWithColor(ctx, [[UIColor grayColor] CGColor]);
     [path setLineWidth:2.0f];
     [path stroke];
     */
    
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return roundedImage;
}


@end

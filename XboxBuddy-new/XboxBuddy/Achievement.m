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
            self.detail = @"Unlock it to find out more.";
        } else {
            self.name = dict[@"Achievement"][@"Name"];
            self.detail = dict[@"Achievement"][@"Description"];
        }
        self.achievementID = dict[@"Achievement"][@"ID"];
        
        self.imageUrl = dict[@"Achievement"][@"UnlockedTileUrl"];
        if (![self.imageUrl isKindOfClass:[NSString class]]) {
            self.imageUrl = dict[@"Achievement"][@"TileUrl"];
        }
        double earnedOn = [dict[@"Achievement"][@"EarnedOn-UNIX"] doubleValue];
        self.earnedOn = [NSDate dateWithTimeIntervalSince1970:earnedOn];
        self.points = [dict[@"Achievement"][@"Score"] integerValue];
        
        self.gamertag = dict[@"Player"][@"Gamertag"];
        self.gamerscore = [dict[@"Player"][@"Gamerscore"] integerValue];
        self.gamerpicImageUrl = dict[@"Player"][@"Avatar"][@"Gamerpic"][@"Large"];
        self.avatarImageUrl = dict[@"Player"][@"Avatar"][@"Body"];
        
        
        self.game = [[Game alloc] initWithDictionary:dict[@"Game"]];
    }
    return self;
}


// TODO: move this to util file
+(NSString *)timeAgoWithDate:(NSDate *)date {

    double timeAgoInSeconds = (double)abs([date timeIntervalSinceNow]);

    if (timeAgoInSeconds == 0) {
        return @"Just Now";
    } else if (timeAgoInSeconds < 60) {
        NSString *s = [NSString stringWithFormat:(timeAgoInSeconds > 1) ? @"s" : @""];
        return [NSString stringWithFormat:@"%.0f second%@ ago", timeAgoInSeconds, s];
    } else if (timeAgoInSeconds < 3600) {
        double seconds = floor(timeAgoInSeconds/60);
        NSString *s = [NSString stringWithFormat:(seconds > 1) ? @"s" : @""];
        return [NSString stringWithFormat:@"%.0f minute%@ ago", seconds, s];
    } else if (timeAgoInSeconds < 86400) {
        double minutes = floor(timeAgoInSeconds/3600);
        NSString *s = [NSString stringWithFormat:(minutes > 1) ? @"s" : @""];
        return [NSString stringWithFormat:@"%.0f hour%@ ago", minutes, s];
    } else if (timeAgoInSeconds < 86400 * 7) {
        double hours = floor(timeAgoInSeconds/86400);
        NSString *s = [NSString stringWithFormat:(hours > 1) ? @"s" : @""];
        return [NSString stringWithFormat:@"%.0f day%@ ago", hours, s];
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

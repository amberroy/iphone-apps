//
//  UserAchievementCell.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/4/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "UserAchievementCell.h"

@interface UserAchievementCell ()

@property Achievement *achievementObj;

@end

@implementation UserAchievementCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)initWithAchievement:(Achievement *)achievementObj
{
    self.achievementObj = achievementObj;
    
    UIImage *gamerpicImage;
    NSString *gamerpicPath = [XboxLiveClient filePathForImageUrl:achievementObj.gamerpicImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gamerpicPath]) {
        gamerpicImage = [UIImage imageWithContentsOfFile:gamerpicPath];
    } else {
        NSLog(@"Gamerpic image not found, using placeholder instead of %@", gamerpicPath);
        gamerpicImage = [UIImage imageNamed:@"TempGamerImage.png"];
    }
    self.gamerImage.image = gamerpicImage;
    
    UIImage *achievementImage;
    NSString *achievementPath = [XboxLiveClient filePathForImageUrl:achievementObj.imageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:achievementPath]) {
        achievementImage = [UIImage imageWithContentsOfFile:achievementPath];
    } else {
        NSLog(@"Achievemnt image not found, using placeholder instead of %@", achievementPath);
        achievementImage = [UIImage imageNamed:@"TempAchievementImage.png"];
    }
    self.achievementImage.image = achievementImage;
    
    self.gamertag.text = achievementObj.gamertag;
    self.achievementPoints.text = [NSString stringWithFormat:@"%i G achievement", achievementObj.points];
    self.gameName.text = achievementObj.game.name;
    self.achievementEarnedOn.text = [Achievement timeAgoWithDate:achievementObj.earnedOn];
}

@end

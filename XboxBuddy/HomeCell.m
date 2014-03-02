//
//  HomeCell.m
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "HomeCell.h"
#import "Achievement.h"

@interface HomeCell ()

@property Achievement *achievementObj;

@end

@implementation HomeCell

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
    if (!achievementObj.gamertag) {
        self.gamerTag.text = nil;
        self.achievementPoints.text = nil;
        self.gameName.text = nil;
        self.achievementEarnedOn.text = nil;
        return;
    }
    
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
    
    UIImage *achievemntImage;
    NSString *achievementPath = [XboxLiveClient filePathForImageUrl:achievementObj.imageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:achievementPath]) {
        achievemntImage = [UIImage imageWithContentsOfFile:achievementPath];
    } else {
        NSLog(@"Achievemnt image not found, using placeholder instead of %@", gamerpicPath);
        achievemntImage = [UIImage imageNamed:@"TempAchievementImage.png"];
    }
    self.achievementImage.image = achievemntImage;
    
    self.gamerTag.text = achievementObj.gamertag;
    self.achievementPoints.text = [NSString stringWithFormat:@"%i G achievement", achievementObj.points];
    self.gameName.text = [NSString stringWithFormat:@"%@", achievementObj.game.name];
    self.achievementEarnedOn.text = [Achievement timeAgoWithDate:achievementObj.earnedOn];
    
}

@end

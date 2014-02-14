//
//  AchievementViewController.m
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "AchievementViewController.h"
#import "XboxLiveClient.h"

@interface AchievementViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *gamerImage;
@property (strong, nonatomic) IBOutlet UILabel *gamerTag;
@property (strong, nonatomic) IBOutlet UIImageView *achievementImage;
@property (strong, nonatomic) IBOutlet UILabel *achievementName;
@property (strong, nonatomic) IBOutlet UILabel *achievementEarnedOn;
@property (strong, nonatomic) IBOutlet UILabel *achievementDescription;
@property (strong, nonatomic) IBOutlet UIImageView *gameBoxImage;

@end

@implementation AchievementViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.gamerTag.text = self.achievement.gamertag;
    self.achievementName.text = self.achievement.name;
    self.achievementDescription.text = self.achievement.detail;
    self.achievementEarnedOn.text = [Achievement timeAgoWithDate:self.achievement.earnedOn];
    
    UIImage *gamerpicImage;
    NSString *gamerpicPath = [XboxLiveClient filePathForImageUrl:self.achievement.gamerpicImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gamerpicPath]) {
        gamerpicImage = [UIImage imageWithContentsOfFile:gamerpicPath];
    } else {
        gamerpicImage = [UIImage imageNamed:@"TempGamerImage.png"];
        NSLog(@"Gamerpic image not found, using placeholder instead of %@", gamerpicPath);
    }
    self.gamerImage.image = [XboxLiveClient createRoundedUserWithImage:gamerpicImage];
    self.achievementImage.image = [self.achievement imageFromAchievement];

    UIImage *boxArtImage;
    NSString *boxArtPath = [XboxLiveClient filePathForImageUrl:self.achievement.gameImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:boxArtPath]) {
        boxArtImage = [UIImage imageWithContentsOfFile:boxArtPath];
    } else {
        boxArtImage = [UIImage imageNamed:@"TempBoxArt.jpg"];
        NSLog(@"Box Art image not found, using placeholder instead of %@", boxArtPath);
    }
    self.gameBoxImage.image = boxArtImage;
    
    
}

@end

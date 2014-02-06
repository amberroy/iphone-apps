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

    UIImage *placeholderImage = [UIImage imageNamed:@"TempGamerImage.png"];
    self.gamerImage.image = [XboxLiveClient createRoundedUserWithImage:placeholderImage];
    self.gamerTag.text = self.achievement.gamertag;
    self.achievementName.text = self.achievement.name;
    self.achievementImage.image = [UIImage imageNamed:@"TempAchievementImage.jpg"];
    self.gameBoxImage.image = [UIImage imageNamed:@"TempBoxArt.jpg"];
    self.achievementDescription.text = self.achievement.description;
}

@end

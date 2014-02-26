//
//  AchievementViewController.m
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "AchievementViewController.h"
#import "HomeTableViewController.h"
#import "Comment.h"
#import "ParseClient.h"
#import <Parse/Parse.h>

@interface AchievementViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *gamerImage;
@property (strong, nonatomic) IBOutlet UILabel *gamerTag;
@property (strong, nonatomic) IBOutlet UIImageView *achievementImage;
@property (strong, nonatomic) IBOutlet UILabel *achievementName;
@property (strong, nonatomic) IBOutlet UILabel *achievementDescription;
@property (strong, nonatomic) IBOutlet UILabel *achievementEarnedOn;
@property (weak, nonatomic) IBOutlet UILabel *achievementPoints;
@property (weak, nonatomic) IBOutlet UILabel *gameName;

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
    self.gameName.text = [NSString stringWithFormat:@"%@", self.achievement.gameName];
    
    self.achievementName.text = self.achievement.name;
    self.achievementPoints.text = [NSString stringWithFormat:@"%ld G", (long)self.achievement.points];
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
    self.gamerImage.image = gamerpicImage;
    
    UIImage *achievmentImage;
    NSString *achievementPath = [XboxLiveClient filePathForImageUrl:self.achievement.imageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:achievementPath]) {
        achievmentImage = [UIImage imageWithContentsOfFile:achievementPath];
    } else {
        achievmentImage = [UIImage imageNamed:@"TempAchievementImage.jpg"];
        NSLog(@"Achievement image not found, using placeholder instead of %@", achievementPath);
    }
    self.achievementImage.image = achievmentImage;
    [HomeTableViewController customizeNavigationBar:self];
    
    // TODO: Put comments in a table.
    NSArray *comments = [[ParseClient instance] commentsForAchievement:self.achievement];
    if (comments) {
        NSLog(@"Comments on %@ achievement %@:", self.achievement.gamertag, self.achievement.name);
    }
    for (Comment *comment in comments) {
        NSLog(@"    \"%@\" by %@ on %@", comment.content, comment.authorGamertag, comment.timestamp);
    }
    
    // TODO: Display Like count on UI.
    NSArray *likes = [[ParseClient instance] likesForAchievement:self.achievement];
    if (likes) {
        NSLog(@"Likes on %@ achievement %@:", self.achievement.gamertag, self.achievement.name);
    }
    for (Like *like in likes) {
        NSLog(@"    %@ on %@", like.authorGamertag, like.timestamp);
    }
    
    
    // EXAMPLE CODE for Push Notifications
//    PFQuery *pushQuery = [PFInstallation query];
//    [pushQuery whereKey:@"deviceType" equalTo:@"ios"];
//    [pushQuery whereKey:@"gamertag" equalTo:self.achievement.gamertag];
//    NSString *message = [NSString stringWithFormat:@"%@ liked your achievement %@: %@",
//                         [User currentUser].gamerTag, self.achievement.gameName, self.achievement.name];
//    [PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:message];
    
    
//    // EXAMPLE CODE how to create and save Like
//    Like *like = [[Like alloc] initWithAchievement:self.achievement];
//    [[ParseClient instance] saveLike:like];
    
}

@end

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

@property (weak, nonatomic) IBOutlet UIButton *likeButton;

@property BOOL isLiked;

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
    
    // Change Like icon if this user has liked this achievement already.
    NSArray *likes = [[ParseClient instance] likesForAchievement:self.achievement];
    for (Like *like in likes) {
        if ([like.authorGamertag isEqualToString:[User currentUser].gamerTag]) {
            self.isLiked = YES;
            break;
        }
    }
    [self updatedIsLiked];
    
    // TODO: Display Like count on UI, for now dump to log.
    if (likes) {
        NSLog(@"Likes on %@ achievement %@:", self.achievement.gamertag, self.achievement.name);
    }
    for (Like *like in likes) {
        NSLog(@"    %@ on %@", like.authorGamertag, like.timestamp);
    }
             
    // TODO: Put comments in a table, for now dump to log.
    NSArray *comments = [[ParseClient instance] commentsForAchievement:self.achievement];
    if (comments) {
        NSLog(@"Comments on %@ achievement %@:", self.achievement.gamertag, self.achievement.name);
    }
    for (Comment *comment in comments) {
        NSLog(@"    \"%@\" by %@ on %@", comment.content, comment.authorGamertag, comment.timestamp);
    }
    
}

- (IBAction)like:(id)sender {
    
    if (self.isLiked) {
        // Don't let this user like the same achievement twice.
        [self updatedIsLiked];
        return;
    }
    self.isLiked = YES;
    [self updatedIsLiked];
    
    Like *like = [[Like alloc] initWithAchievement:self.achievement];
    [[ParseClient instance] saveLike:like];
    
    [ParseClient sendPushNotification:@"liked" withAchievement:self.achievement];
}

- (void)updatedIsLiked
{
    // TODO: There is some bug with changing the image.
    if (self.isLiked) {
        self.likeButton.imageView.image = [UIImage imageNamed:@"like-26.png"];
    } else {
        self.likeButton.imageView.image = [UIImage imageNamed:@"like_outline-26.png"];
    }
    
}



@end

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

@property (weak, nonatomic) IBOutlet UIButton *heartButton;

@property NSMutableArray *likes;
@property NSMutableArray *comments;
@property Like *currentUserLike;

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
    [HomeTableViewController customizeNavigationBar:self];

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
    
    // Get Comments and Likes (already downloaded by ParseClient on app load).
    self.comments = [[ParseClient instance] commentsForAchievement:self.achievement];
    self.likes = [[ParseClient instance] likesForAchievement:self.achievement];
    self.currentUserLike = [self uniqueCurrentUserLike];
    [self updateLikeButtonImage];
    
    // TODO: Put comments in a table, for now dump to log.
    if (self.comments) {
        NSLog(@"Comments on %@ achievement %@:", self.achievement.gamertag, self.achievement.name);
        for (Comment *comment in self.comments) {
            NSLog(@"    \"%@\" by %@ on %@", comment.content, comment.authorGamertag, comment.timestamp);
        }
    }
    
}

- (Like *)uniqueCurrentUserLike
{
    Like *resultLike = nil;
    
    // Use copy in case we need to modify the array within the loop.
    NSMutableArray *likesCopy = [[NSMutableArray alloc] initWithArray:self.likes];
    for (Like *like in likesCopy) {
        
        // Determine if the current user has already Liked this achievement.
        if ([like.authorGamertag isEqualToString:[User currentUser].gamerTag]) {
            if (!resultLike) {
                resultLike = like;
            } else {
                // Somehow the user liked this achievement more than once, delete extra Likes.
                // Shouldn't happen but Parse will allow it (no unique constraints).
                [self.likes removeObject:like];
                [[ParseClient instance] deleteLike:like];
                NSLog(@"Warning: multiple likes by %@ on %@:%@:%@",
                      like.authorGamertag, like.achievementGamertag, like.gameName, like.achievementName);
            }
        }
    }
    return resultLike;
}

- (IBAction)like:(id)sender {
    
    ParseClient *parseClient = [ParseClient instance];
    
    if (!self.currentUserLike) {
        Like *like = [[Like alloc] initWithAchievement:self.achievement];
        self.currentUserLike = like;
        [self.likes addObject:like];
        [parseClient saveLike:like];
        
        // Don't send notification if use liked their own achievement.
        if (![self.achievement.gamertag isEqualToString:[User currentUser].gamerTag]) {
            [ParseClient sendPushNotification:@"liked" withAchievement:self.achievement];
        }
    } else {
        // Un-like.
        [self.likes removeObject:self.currentUserLike];
        [parseClient deleteLike:self.currentUserLike];
        self.currentUserLike = nil;
    }
    [self updateLikeButtonImage];
}

- (void)updateLikeButtonImage
{
    if (self.currentUserLike) {
        [self.heartButton setImage:[UIImage imageNamed:@"like-26.png"] forState:UIControlStateNormal];
    } else {
        [self.heartButton setImage:[UIImage imageNamed:@"like_outline-26.png"] forState:UIControlStateNormal];
    }
}



@end

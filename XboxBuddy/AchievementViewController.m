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
#import "CommentCell.h"
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
@property (weak, nonatomic) IBOutlet UIImageView *currentUserImage;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property NSMutableArray *likes;
@property NSMutableArray *comments;
@property Like *currentUserLike;

@property CGRect textFieldFrame;
@property CGRect userImageFrame;

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
    self.gameName.text = [NSString stringWithFormat:@"%@", self.achievement.game.name];
    
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
    
    UIImage *userImage;
    Profile *userProfile = [[XboxLiveClient instance] userProfile];
    NSString *userImagePath = [XboxLiveClient filePathForImageUrl:userProfile.gamerpicImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:userImagePath]) {
        userImage = [UIImage imageWithContentsOfFile:userImagePath];
    } else {
        userImage = [UIImage imageNamed:@"TempAchievementImage.jpg"];
        NSLog(@"Achievement image not found, using placeholder instead of %@", userImagePath);
    }
    self.currentUserImage.image = userImage;
    
    [self reloadLikes];
    
}

- (void)reloadLikes
{
    // Get Comments and Likes (already downloaded by ParseClient on app load).
    self.comments = [[ParseClient instance] commentsForAchievement:self.achievement];
    self.likes = [[ParseClient instance] likesForAchievement:self.achievement];
    self.currentUserLike = nil;
    for (Like *like in self.likes) {
        if ([like.authorGamertag isEqualToString:[User currentUser].gamerTag]) {
            self.currentUserLike = like;
            break;
        }
    }
    if (self.currentUserLike) {
        [self.heartButton setImage:[UIImage imageNamed:@"like-26.png"] forState:UIControlStateNormal];
    } else {
        [self.heartButton setImage:[UIImage imageNamed:@"like_outline-26.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)like:(id)sender {
    
    ParseClient *parseClient = [ParseClient instance];
    
    if (!self.currentUserLike) {
        Like *like = [[Like alloc] initWithAchievement:self.achievement];
        self.currentUserLike = like;
        [self.likes addObject:like];
        [parseClient saveLike:like];
        
        // Don't send notification if user liked their own achievement.
        if (![self.achievement.gamertag isEqualToString:[User currentUser].gamerTag]) {
            [ParseClient sendPushNotification:@"liked" withAchievement:self.achievement];
        }
    } else {
        // Un-like.
        [self.likes removeObject:self.currentUserLike];
        [parseClient deleteLike:self.currentUserLike];
        self.currentUserLike = nil;
    }
    [self reloadLikes];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Keep textField visible when keyboard is displayed.
    // Hide tableView and move textField up to where the table was.
    [self.tableView setHidden:YES];
    CGRect tableFrame = self.tableView.frame;
    CGRect textFrame = textField.frame;
    CGRect imageFrame = self.currentUserImage.frame;
    self.textFieldFrame = textFrame;
    self.userImageFrame = imageFrame;
    textFrame.origin.y = tableFrame.origin.y;
    imageFrame.origin.y = tableFrame.origin.y;
    textField.frame = textFrame;
    self.currentUserImage.frame = imageFrame;
    
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    Comment *comment = [[Comment alloc] initWithContent:textField.text withAchievement:self.achievement];
    [self.comments addObject:comment];
    [self.tableView reloadData];
    self.tableView.hidden = NO;
    textField.text = nil;
    [textField resignFirstResponder];
    
    [[ParseClient instance] saveComment:comment];
    
    // Don't send notification if user commented on their own achievement.
    if (![self.achievement.gamertag isEqualToString:[User currentUser].gamerTag]) {
        [ParseClient sendPushNotification:@"commented on" withAchievement:self.achievement];
    }
    
    // Show table view and move image and textField back to original locations.
    [self.tableView setHidden:NO];
    [self.tableView reloadData];
    textField.frame = self.textFieldFrame;
    self.currentUserImage.frame = self.userImageFrame;
    
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.comments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    CommentCell *cell = (CommentCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Comment *commentObj = self.comments[indexPath.row];
    cell = [cell initWithComment:commentObj];
    
    return cell;
}


@end

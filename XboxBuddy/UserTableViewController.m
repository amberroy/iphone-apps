//
//  UserTableViewController.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/4/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "UserTableViewController.h"
#import "AchievementViewController.h"
#import "UserAchievementCell.h"
#import "Achievement.h"
#import "XboxLiveClient.h"

@interface UserTableViewController ()

@property (nonatomic, strong) NSArray *achievements;

@property (strong, nonatomic) IBOutlet UIImageView *gamerImage;
@property (strong, nonatomic) IBOutlet UILabel *gamerTag;

@end

@implementation UserTableViewController

- (void)setup {
    if (self.profile == nil || self.profile.gamertag == nil) {
        // Show current user's Profile
        self.profile = [[XboxLiveClient instance] userProfile];
    }
    self.achievements = [[XboxLiveClient instance] achievementsWithGamertag:self.profile.gamertag];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // TODO: temporary call to setup, doing this here for now to pick up the data after its been initially loaded
    // we'll need to work out how we want to do data refresh
    [self setup];

    self.gamerTag.text = self.profile.gamertag;
    
    UIImage *gamerpicImage;
    NSString *gamerpicPath = [XboxLiveClient filePathForImageUrl:self.profile.gamerpicImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gamerpicPath]) {
        gamerpicImage = [UIImage imageWithContentsOfFile:gamerpicPath];
    } else {
        gamerpicImage = [UIImage imageNamed:@"TempGamerImage.png"];
        NSLog(@"Gamerpic image not found, using placeholder instead of %@", gamerpicPath);
    }
    self.gamerImage.image = [XboxLiveClient createRoundedUserWithImage:gamerpicImage];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.achievements count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UserAchievementCell";

    UserAchievementCell *cell = (UserAchievementCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Achievement *achievementObj = self.achievements[indexPath.row];

    cell.achievementName.text = achievementObj.name;
    cell.achievementDescription.text = achievementObj.detail;
    cell.achievementEarnedOn.text = [Achievement timeAgoWithDate:achievementObj.earnedOn];

    UIImage *achievementImage;
    NSString *achievementPath = [XboxLiveClient filePathForImageUrl:achievementObj.imageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:achievementPath]) {
        achievementImage = [UIImage imageWithContentsOfFile:achievementPath];
    } else {
        achievementImage = [UIImage imageNamed:@"TempAchievementImage.png"];
        NSLog(@"Achievement image not found, using placeholder instead of %@", achievementPath);
    }
    cell.achievementImage.image = achievementImage;

    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"showAchievementDetail"]) {

        UITableViewCell *selectedCell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedCell];
        Achievement *achievement = self.achievements[indexPath.row];
        AchievementViewController *achieveViewController = (AchievementViewController *)segue.destinationViewController;

        achieveViewController.achievement = achievement;
    }
}

@end

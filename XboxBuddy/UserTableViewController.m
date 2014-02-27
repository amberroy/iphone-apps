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
#import "HomeTableViewController.h"

@interface UserTableViewController ()

@property (nonatomic, strong) NSArray *achievements;

@property (strong, nonatomic) IBOutlet UIImageView *gamerImage;
@property (strong, nonatomic) IBOutlet UILabel *gamertag;
@property (weak, nonatomic) IBOutlet UILabel *gamerscore;

@end

@implementation UserTableViewController

- (void)setup {
    if (self.profile == nil || self.profile.gamertag == nil) {
        // Show current user's Profile
        self.profile = [[XboxLiveClient instance] userProfile];
    }
    self.achievements = [[XboxLiveClient instance] achievementsWithGamertag:self.profile.gamertag];
    
    // Setup the view.
    self.gamertag.text = self.profile.gamertag;
    self.gamerscore.text = [NSString stringWithFormat:@"%i G", self.profile.gamerscore];
    UIImage *gamerpicImage;
    NSString *gamerpicPath = [XboxLiveClient filePathForImageUrl:self.profile.gamerpicImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gamerpicPath]) {
        gamerpicImage = [UIImage imageWithContentsOfFile:gamerpicPath];
    } else {
        gamerpicImage = [UIImage imageNamed:@"TempGamerImage.png"];
        NSLog(@"Gamerpic image not found, using placeholder instead of %@", gamerpicPath);
    }
    self.gamerImage.image = gamerpicImage;
}

- (void)reloadTable:(NSNotification *)notification {
    self.profile = [[XboxLiveClient instance] userProfile];
    [self setup];
    [self.tableView reloadData];
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTable:) name:@"InitialDataLoaded" object:nil];

    
    [HomeTableViewController customizeNavigationBar:self];
    [self setup];
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
    [cell initWithAchievement:achievementObj];
    
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
        achieveViewController.hidesBottomBarWhenPushed = YES;
    }
}

@end

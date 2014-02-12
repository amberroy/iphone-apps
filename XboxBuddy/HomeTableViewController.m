//
//  HomeTableViewController.m
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "HomeTableViewController.h"
#import "AchievementViewController.h"
#import "Achievement.h"
#import "HomeCell.h"
#import "XboxLiveClient.h"

@interface HomeTableViewController ()

@property (nonatomic, strong) NSArray *achievements;

@end

@implementation HomeTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // TODO: currently achievement data assignment is triggered by NSNotification
        //self.achievements = [[XboxLiveClient instance] achievements];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTable:)
                                                 name:@"InitialDataLoaded"
                                               object:nil];

    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.achievements count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HomeCell";

    HomeCell *cell = (HomeCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Achievement *achievementObj = self.achievements[indexPath.row];

    UIImage *gamerpicImage = [UIImage imageNamed:@"TempGamerImage.png"];
    NSString *gamerpicPath = [XboxLiveClient filePathForImageUrl:achievementObj.gamerpicImageUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gamerpicPath]) {
        gamerpicImage = [UIImage imageWithContentsOfFile:gamerpicPath];
    } else {
        NSLog(@"Gamerpic image not found, using placeholder instead of %@", gamerpicPath);
    }
    
    cell.gamerImage.image = [XboxLiveClient createRoundedUserWithImage:gamerpicImage];
    cell.gamerTag.text = achievementObj.gamertag;
    cell.achievementName.text = achievementObj.name;
    cell.achievementEarnedOn.text = [Achievement timeAgoWithDate:achievementObj.earnedOn];

    return cell;
}

- (void)reloadTable:(NSNotification *)notification {
    self.achievements = [[XboxLiveClient instance] achievements];
    [self.tableView reloadData];
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
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

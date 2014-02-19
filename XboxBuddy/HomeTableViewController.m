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

@interface HomeTableViewController ()

@property (nonatomic, strong) NSArray *achievements;

@end

@implementation HomeTableViewController

+ (void)customizeNavigationBar:(UIViewController *)viewController
{
    UIColor *backgroundColor = [UIColor darkGrayColor];
    //UIColor *backgroundColor = [UIColor colorWithRed:0.0/255.0
    //                                           green:159.0/255.0
    //                                            blue:0.0/255.0 alpha:1.0];
    UIColor *textColor = [UIColor whiteColor];
    
    // Custom Nav Bar colors:
    // * NavBar translucent: YES by default, change to NO when adding colors.
    // * NavBar barTintColor: Background color of the nav bar.
    // * NavBar tintcolor: Text color of the back arrow (e.g. "<").
    // * NavBar "NSForgroundColorAttributeName": Text color of title (e.g. "Home").
    // * BarButtonItem "NSForgroundColorAttributeName": Text color of the title when on left ("back") nav button.
    
    // TODO: Move this to util file.
    viewController.navigationController.navigationBar.translucent = NO;
    viewController.navigationController.navigationBar.barTintColor = backgroundColor;
    viewController.navigationController.navigationBar.tintColor = textColor;
    viewController.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: textColor};
    UIBarButtonItem *barButtonItem = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: textColor} forState:UIControlStateNormal];
}

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

    [HomeTableViewController customizeNavigationBar:self];
    [self setUp];
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
    [cell initWithAchievement:achievementObj];

    return cell;
}

- (void)reloadTable:(NSNotification *)notification {
    self.achievements = [[XboxLiveClient instance] achievements];
    [self.tableView reloadData];
}

- (void)setUp
{
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

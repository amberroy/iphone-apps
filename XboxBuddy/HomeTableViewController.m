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
#import "AchievementCell.h"
#import "AppDelegate.h"
#import "ParseClient.h"

@interface HomeTableViewController ()

@property (nonatomic, strong) NSArray *achievements;

@property UIActivityIndicatorView *spinner;
@property AppDelegate *appDelegate;

@end

@implementation HomeTableViewController

+ (void)customizeNavigationBar:(UIViewController *)viewController
{
    UIColor *green = [UIColor colorWithRed:0.0/255.0
                                     green:147.0/255.0
                                      blue:69.0/255.0 alpha:1.0];
    
    //UIColor *backgroundColor = [UIColor darkGrayColor];
    UIColor *textColor = [UIColor blackColor];
    //UIColor *borderColor = [UIColor blackColor];
    
    // Custom Nav Bar colors:
    // * NavBar translucent: YES by default, change to NO when adding colors.
    // * NavBar barTintColor: Background color of the nav bar.
    // * NavBar tintcolor: Text color of the back arrow (e.g. "<").
    // * NavBar "NSForgroundColorAttributeName": Text color of title (e.g. "Home").
    // * BarButtonItem "NSForgroundColorAttributeName": Text color of the title when on left ("back") nav button.
    
    // TODO: Move this to util file.
    UINavigationBar *navigationBar = viewController.navigationController.navigationBar;
    //navigationBar.translucent = NO;
    //navigationBar.barTintColor = backgroundColor;
    navigationBar.tintColor = green;
    navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: textColor};
    UIBarButtonItem *barButtonItem = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil];
    [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: green} forState:UIControlStateNormal];
    
    // Set bottom border for NavBar.
    //CGRect frame = CGRectMake(0, navigationBar.frame.size.height-1,navigationBar.frame.size.width, 1);
    //UIView *navBorder = [[UIView alloc] initWithFrame:frame];
    //[navBorder setBackgroundColor:borderColor];
    //[navBorder setOpaque:YES];
    //[navigationBar addSubview:navBorder];
    
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Special case for launching from Push Notification.
    if (self.appDelegate.didLaunchWithNotification && [[ParseClient instance] isInitialized]) {
        [self processNotification];
    }
    
}

- (void) processNotification
{
    // Before loading table, check for special case: App launched from Push Notification.
    self.appDelegate.didLaunchWithNotification = NO;
    
    // Extract Achievement from payload.
    NSDictionary *notificationPayload = self.appDelegate.notificationPayload;
    NSString *gamertag = notificationPayload[@"gamertag"];
    NSString *gameName = notificationPayload[@"gameName"];
    NSString *achievementName = notificationPayload[@"achievementName"];
    NSString *userGamertag = [User currentUser].gamertag;
    if ([gamertag isEqualToString:userGamertag]) {
        Achievement *achievement = [[XboxLiveClient instance] achievementWithGamertag:gamertag withGameName:gameName withAchievementName:achievementName];
        if (achievement) {
            NSLog(@"Push notification processed, found Achievement: %@:%@:%@", gamertag, gameName, achievementName);
            
            // Show AchievementDetail immediately.
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            AchievementViewController *avc = [storyboard instantiateViewControllerWithIdentifier:@"AchievementViewController"];
            avc.achievement = achievement;
            [self.navigationController pushViewController:avc animated:YES];
        } else {
            NSLog(@"Ignoring Push notification, achievemnt not found: %@:%@:%@", gamertag, gameName, achievementName);
        }
    } else {
        NSLog(@"Ignoring Push notification, sent to %@ but current user is %@", gamertag, userGamertag);
    }
    
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
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

    [HomeTableViewController customizeNavigationBar:self];
    [self setUp];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.achievements count] == 0) {
        return 1;
    }
    return [self.achievements count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HomeAchievementCell";

    AchievementCell *cell = (AchievementCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if ([self.achievements count] == 0) {
        self.spinner.center = cell.center;
        [cell addSubview:self.spinner];
        [self.spinner startAnimating];
        [cell initWithAchievement:[[Achievement alloc] init]];
        return cell;
    }
    
    Achievement *achievementObj = self.achievements[indexPath.row];
    [cell initWithAchievement:achievementObj];

    return cell;
}

- (void)reloadTable:(NSNotification *)notification {
    
    // All clients initialized!
    self.achievements = [[XboxLiveClient instance] achievements];
    [self.tableView reloadData];
    
    // Special case for launching from Push Notification.
    if (self.appDelegate.didLaunchWithNotification && [[ParseClient instance] isInitialized]) {
        [self processNotification];
    }
}

- (void)setUp
{
    // If ParseClient not done initializing, don't load data from XboxLiveClient,
    // but call reloadData anyway which will start the spinner animation.
    if ([[ParseClient instance] isInitialized]) {
        self.achievements = [[XboxLiveClient instance] achievements];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"showAchievementDetail"] ||
        [segue.identifier isEqualToString:@"showAchievementDetailFocusComment"]) {

        UITableViewCell *selectedCell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedCell];
        Achievement *achievement = self.achievements[indexPath.row];
        AchievementViewController *achieveViewController = (AchievementViewController *)segue.destinationViewController;

        achieveViewController.achievement = achievement;
        achieveViewController.hidesBottomBarWhenPushed = YES;
        
        if ([segue.identifier isEqualToString:@"showAchievementDetailFocusComment"]) {
            achieveViewController.focusCommentTextField = YES;
        } else {
            achieveViewController.focusCommentTextField = NO;
        }
    }
}

#pragma mark - SwipeWithOptionsCellDelegate Methods

// TODO: add initial fill with liked items

-(void)cellDidSelect:(SwipeWithOptionsCell *)cell {
    [self performSegueWithIdentifier: @"showAchievementDetail" sender:cell];
}

-(void)cellDidSelectComment:(SwipeWithOptionsCell *)cell {
    [self performSegueWithIdentifier: @"showAchievementDetailFocusComment" sender:cell];
}

-(void)cellDidSelectLike:(SwipeWithOptionsCell *)cell {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Achievement *achievement = self.achievements[indexPath.row];
    
    ParseClient *parseClient = [ParseClient instance];
    
    Like *like = [[Like alloc] initWithAchievement:achievement];
    [parseClient saveLike:like];
    
    if (![achievement.gamertag isEqualToString:[User currentUser].gamertag]) {
        [ParseClient sendPushNotification:@"liked" withAchievement:achievement];
    }
    [cell.likeButton setImage:[UIImage imageNamed:@"icon_likeFilled.png"] forState:UIControlStateNormal];
    
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

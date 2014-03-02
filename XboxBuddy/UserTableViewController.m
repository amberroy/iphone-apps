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
#import "ParseClient.h"
#import "Invitation.h"

@interface UserTableViewController ()

@property (nonatomic, strong) NSArray *achievements;

@property (strong, nonatomic) IBOutlet UIImageView *gamerImage;
@property (strong, nonatomic) IBOutlet UILabel *gamertag;
@property (weak, nonatomic) IBOutlet UILabel *gamerscore;

@property BOOL isCurrentUser;

@end

@implementation UserTableViewController

- (void)setup {
    if (self.profile == nil || self.profile.gamertag == nil) {
        // Show current user's Profile
        self.profile = [[XboxLiveClient instance] userProfile];
        self.isCurrentUser = YES;
    }
    if (![self.profile.gamertag isEqualToString:[User currentUser].gamerTag]) {
        // Hide the Settings button if this profile is not for the current user.
        self.navigationItem.rightBarButtonItem.image = nil;
        self.navigationItem.rightBarButtonItem.title = @"Invite";
        self.navigationItem.rightBarButtonItem.tintColor = self.navigationController.navigationBar.tintColor;
        self.isCurrentUser = NO;
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

- (IBAction)rightBarButton:(id)sender {
    // Right bar button shows Settings icon if this is the current users profile,
    // otherwise it says "Invite" which sends mail to invite this friend to our app.
    UIBarButtonItem *barButton = (UIBarButtonItem *)sender;
    ([barButton.title isEqualToString:@"Invite"]) ? [self presentMail] : [self presentSettings];
}

- (void) presentSettings
{
    AchievementViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) presentMail
{
    NSString *subject = [NSString stringWithFormat:@"join me on XBoxBuddy"];
    NSString *body = [NSString stringWithFormat:
                      @"Hello %@,\nJoin me on XboxBuddy, the new iPhone app for Xbox gamers.\n\n-%@",
                      self.profile.gamertag, [User currentUser].gamerTag];
        
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setSubject:subject];
    [mailComposer setMessageBody:body isHTML:NO];
    [self presentViewController:mailComposer animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail compose result: Cancalled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail compose result: Saved");
            break;
        case MFMailComposeResultSent: {
            NSLog(@"Mail compose result: Sent");
            // TODO: If we already invited this friend, don't show the "Invite" button.
            //Invitation *invitation = [[Invitation alloc] initWithRecipient:self.profile.gamertag];
            //[[ParseClient instance] saveInvitation:invitation];
            break;
        }
        case MFMailComposeResultFailed:
            NSLog(@"Mail compose result: Failed");
            break;
        default:
            break;
    }
    
    if (error) {
        NSLog(@"Error sending mail: %@", error);
    }
}


@end

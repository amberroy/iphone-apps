//
//  UserTableViewController.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/4/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "UserTableViewController.h"
#import "AchievementViewController.h"
#import "Achievement.h"
#import "HomeTableViewController.h"
#import "ParseClient.h"
#import "Invitation.h"
#import "AchievementCell.h"
#import "ParseClient.h"
#import <Parse/Parse.h>

@interface UserTableViewController ()

@property NSArray *achievements;
@property Invitation *invitation;
@property BOOL isCurrentUser;

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
    self.isCurrentUser = [self.profile.gamertag isEqualToString:[User currentUser].gamertag];
    if (!self.isCurrentUser) {
        // Hide the Settings button if this profile is not for the current user.
        self.navigationItem.rightBarButtonItem.image = nil;
        
        self.invitation = [[ParseClient instance] invitationForGamertag:self.profile.gamertag];
        if (!self.invitation) {
            // Only show Invite button if we haven't already invited this user.
            self.navigationItem.rightBarButtonItem.title = @"Invite";
            self.navigationItem.rightBarButtonItem.tintColor = self.navigationController.navigationBar.tintColor;
        } else {
            if (XboxLiveClient.isDemoMode) {
                // For demo, add hidden button for undo-ing Invitations.
                self.navigationItem.rightBarButtonItem.title = @"      ";
            }
        }
    }
    self.achievements = [[XboxLiveClient instance] achievementsWithGamertag:self.profile.gamertag];
    
    // Setup the view.
    self.gamertag.text = self.profile.gamertag;
    self.gamerscore.text = [NSString stringWithFormat:@"%li G", (long)self.profile.gamerscore];
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
    
    AchievementCell *cell = (AchievementCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.accessoryType = UITableViewCellAccessoryNone;

    Achievement *achievementObj = self.achievements[indexPath.row];
    [cell initWithAchievement:achievementObj];
    
    return cell;
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

- (IBAction)rightBarButton:(id)sender {
    // Right bar button shows Settings icon if this is the current users profile,
    // otherwise it says "Invite" which sends mail to invite this friend to our app.
    if (self.isCurrentUser) {
        [self presentSettings];
    } else {
        if (!self.invitation) {
            [self presentMail];
        } else {
            // Hidden button deletes the invitation.
            [[ParseClient instance] deleteInvitation:self.invitation];
            self.invitation = nil;
            [self setup];
        }
        
    }
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
                      self.profile.gamertag, [User currentUser].gamertag];
        
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
    
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail compose result: Cancalled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail compose result: Saved");
            break;
        case MFMailComposeResultSent: {
            NSLog(@"Mail compose result: Sent");
            Invitation *invitation = [[Invitation alloc] initWithRecipient:self.profile.gamertag];
            [[ParseClient instance] saveInvitation:invitation];
            [self setup];
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
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SwipeWithOptionsCellDelegate Methods

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

@end

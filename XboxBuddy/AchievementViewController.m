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

@property (weak, nonatomic) IBOutlet UIView *achievementBackgroundView;
@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
@property (weak, nonatomic) IBOutlet UIView *textFieldBackgroundView;

@property NSMutableArray *likes;
@property NSMutableArray *comments;
@property Like *currentUserLike;
@property BOOL isCurrentUserAchievement;

//@property CGRect textFieldFrame;
//@property CGRect userImageFrame;
@property CGRect originalTextFieldBackgroundFrame;
@property CGRect originalTableViewFrame;

@property Comment *commentPendingDelete;


@end

@implementation AchievementViewController

typedef NS_ENUM(NSInteger, AlertViewTag) {
    AlertViewDeleteCommentTag,
    AlertViewInviteFriendTag,
};

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
    self.isCurrentUserAchievement = [self.achievement.gamertag isEqualToString:[User currentUser].gamertag];
    
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
    
    // Add border around achievement.
    self.achievementBackgroundView.layer.borderColor = [UIColor blackColor].CGColor;
    self.achievementBackgroundView.layer.borderWidth = 1.0f;
    
    // Don't show separators for empty rows in comments table.
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    v.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:v];
    
    // Remember original location of views.
    self.originalTextFieldBackgroundFrame = self.textFieldBackgroundView.frame;
    self.originalTableViewFrame = self.tableView.frame;
    
    [self reloadLikes];
    
}

- (void)reloadLikes
{
    // Get Comments and Likes (already downloaded by ParseClient on app load).
    self.comments = [[ParseClient instance] commentsForAchievement:self.achievement];
    self.likes = [[ParseClient instance] likesForAchievement:self.achievement];
    self.currentUserLike = nil;
    for (Like *like in self.likes) {
        if ([like.authorGamertag isEqualToString:[User currentUser].gamertag]) {
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
        if (!self.isCurrentUserAchievement) {
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
    [self moveTextFieldLocation:textField];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonSystemItemCancel target:self action:@selector(cancelComment)];
    
    return YES;
}

- (void) cancelComment
{
    // Remove Cancel button.
    [self resetTextFieldLocation:self.commentTextField];
    [self.commentTextField resignFirstResponder];
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
    if (!self.isCurrentUserAchievement) {
        [ParseClient sendPushNotification:@"commented on" withAchievement:self.achievement];
    }
    
    NSString *friendGamertag = self.achievement.gamertag;
    User *friendUserObj = [[ParseClient instance] userForGamertag:friendGamertag];
    Invitation *friendInvitation = [[ParseClient instance] invitationForGamertag:friendGamertag];
    if (!self.isCurrentUserAchievement && !friendUserObj && !friendInvitation) {
        
        // If friend is not using our app and hasn't been invited, show alert offering to invite them.
        NSString *message = [NSString stringWithFormat:@"%@ won't see your comment until they install this app.  Send email invitation.", friendGamertag];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invite Friend"
                message:message delegate:self cancelButtonTitle:@"Not now" otherButtonTitles:@"OK", nil];
        alert.tag = AlertViewInviteFriendTag;
        [alert show];
    }
    
    [self resetTextFieldLocation:self.commentTextField];
    
    return YES;
}

- (void) moveTextFieldLocation:(UITextField *)textField
{
    // Keep textField visible when keyboard is displayed.
    // Hide tableView and move textField up to where the table was.
//    [self.tableView setHidden:YES];
//    CGRect tableFrame = self.tableView.frame;
//    CGRect textFrame = textField.frame;
//    CGRect imageFrame = self.currentUserImage.frame;
//    self.textFieldFrame = textFrame;
//    self.userImageFrame = imageFrame;
//    textFrame.origin.y = tableFrame.origin.y;
//    imageFrame.origin.y = tableFrame.origin.y;
//    textField.frame = textFrame;
//    self.currentUserImage.frame = imageFrame;
    
    [self.tableView setHidden:YES];
    CGRect newFrame = self.textFieldBackgroundView.frame;
    newFrame.origin.y = self.originalTableViewFrame.origin.y;
    self.textFieldBackgroundView.frame = newFrame;
    
}

- (void) resetTextFieldLocation:(UITextField *)textField
{
//    // Show table view and move image and textField back to original locations.
//    [self.tableView setHidden:NO];
//    [self.tableView reloadData];
//    textField.frame = self.textFieldFrame;
//    self.currentUserImage.frame = self.userImageFrame;
    
    [self.tableView setHidden:NO];
    self.textFieldBackgroundView.frame = self.originalTextFieldBackgroundFrame;
    
    // Clear bar button and text input.
    self.navigationItem.rightBarButtonItem = nil;
    textField.text = nil;
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


#pragma mark - UITableViewCell buttons
-(void)deleteButtonPressed:(UIButton *)sender
{
    CommentCell *commentCell = (CommentCell *)sender.superview.superview.superview;
    self.commentPendingDelete = commentCell.commentObj;
    
    NSString *message = @"Delete this comment?";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Delete"
            message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    alert.tag = AlertViewDeleteCommentTag;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    switch (alertView.tag) {
            
        case AlertViewDeleteCommentTag:
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self.comments removeObject:self.commentPendingDelete];
                [self.tableView reloadData];
                
                [[ParseClient instance] deleteComment:self.commentPendingDelete];
            }
            break;
            
        case AlertViewInviteFriendTag:
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self presentMail];
            }
            break;
    }
}

- (void) presentMail
{
    NSString *subject = [NSString stringWithFormat:@"join me on XBoxBuddy"];
    NSString *body = [NSString stringWithFormat:
                      @"Hello %@,\nJoin me on XboxBuddy, the new iPhone app for Xbox gamers.\n\n-%@",
                      self.achievement.gamertag, [User currentUser].gamertag];
    
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
            Invitation *invitation = [[Invitation alloc] initWithRecipient:self.achievement.gamertag];
            [[ParseClient instance] saveInvitation:invitation];
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

@end

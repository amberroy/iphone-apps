//
//  MasterViewController.m
//  TwitterClone
//
//  Created by Amber Roy on 1/23/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "TimelineViewController.h"

#import "TweetViewController.h"
#import "TweetCell.h"
#import "Tweet.h"

@interface TimelineViewController ()
-(void) loginWithUsername:(NSString *)username;
@end

@implementation TimelineViewController
{
    NSMutableArray *_tweets;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //return _tweets.count;
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TweetCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TweetCell" forIndexPath:indexPath];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tweets[indexPath.row][@"tweetImage"]) {
        return 155;         // Height of prototype cell, with tweetImage.
    } else {
        return 155 - 76;    // Above minus the height of the tweetImage.
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showTweet"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Tweet *tweet = _tweets[indexPath.row];
        TweetViewController *tvc = (TweetViewController *)segue.destinationViewController;
        [tvc setTweet:tweet];
    } if ([segue.identifier isEqualToString:@"showLogin"]) {
        // TODO - logout the current user
        NSLog(@"Logout not yet implemented");
        [segue.destinationViewController setDelegate:self];
    } else if ([segue.identifier isEqualToString:@"showCompose"]) {
        [segue.destinationViewController setReplyTo:nil];
        [segue.destinationViewController setDelegate:self];
    }
}

#pragma mark - LoginViewControllerDelegate
-(void)loginViewControllerDidFinish:(LoginViewController *)controller
{
    LoginViewController *lvc = (LoginViewController *)controller;
    NSLog(@"Login successful for user %@", lvc.usernameField.text);
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ComposeViewControllerDelegate
-(void)composeViewControllerDidFinish:(ComposeViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Twitter API

-(void) loginWithUsername:(NSString *)username;
{

    //NSString *url = [NSString stringWithFormat:
    //                 @"http://api.twitter.com/oauth/authenticate&screen_name=%@", username];

}



//NSURL *url = [NSURL URLWithString:DVD_URL];
//NSURLRequest *request = [NSURLRequest requestWithURL:url];
//[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
// ~~~completionHandler:
// ~~~^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//     ~~~if (connectionError) { NSLog(@"ERROR connecting to %@",DVD_URL); } else {
//         ~~~id object=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//         ~~~NSLog(@"%@", object);  }}];  // Can use NSDictionary instead of id above.
//}

@end

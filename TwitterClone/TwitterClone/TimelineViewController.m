//
//  TimelineViewController.m
//  TwitterClone
//
//  Created by Amber Roy on 1/23/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "TimelineViewController.h"

#import "TweetViewController.h"
#import "TweetCell.h"
#import "Tweet.h"
#import "TwitterAPI.h"

@interface TimelineViewController ()

- (void)refreshView:(UIRefreshControl *)refresh;

@property NSInteger lastScroll;

@property TwitterAPI *twitterAPI;
@property NSMutableArray *dataFromTwitter;

@property Tweet *currentUserInfo;
@property NSMutableArray *tweets;

@property BOOL isAuthenticated;
@property UIActivityIndicatorView *spinner;

@end

@implementation TimelineViewController
{
    
    
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tweets = [[NSMutableArray alloc] init];
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.isAuthenticated = NO;
    self.twitterAPI = [[TwitterAPI alloc] init];
    
    // Custom Nav Bar colors.
    [self.navigationController.navigationBar setBarTintColor:
         [UIColor colorWithRed:121.0/255.0 green:184.0/255.0 blue:2350.0/255.0 alpha:1.0]];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary
           dictionaryWithObject:[UIColor whiteColor] forKey:UITextAttributeTextColor]];
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
         setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],
         UITextAttributeTextColor,nil] forState:UIControlStateNormal];             // Set back button color
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];  // Set back button arrow color
    
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh"];
    [refresh addTarget:self action:@selector(refreshView:)
      forControlEvents:UIControlEventValueChanged];
    self.refreshControl=refresh;
    
    [self.twitterAPI setDelegate:self];
    [self.twitterAPI accessTwitterAPI:HOME_TIMELINE parameters:nil];
    [self.twitterAPI accessTwitterAPI:SHOW_CURRENT_USER parameters:nil];
}

- (void)refreshView:(UIRefreshControl *)refresh;
{
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing data..."];
    [self.twitterAPI accessTwitterAPI:HOME_TIMELINE parameters:nil];
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Updating Data"];
    [refresh endRefreshing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPushRefresh:(id)sender {
    [self.spinner startAnimating];
    [self.twitterAPI accessTwitterAPI:HOME_TIMELINE parameters:nil];
}

#pragma mark - UITableViewCell buttons
-(void)retweetButtonPressed:(UIButton *)sender
{
    TweetCell *tweetCell = (TweetCell *)sender.superview.superview.superview;
    Tweet *tweet = tweetCell.tweet;
    if (tweet.retweeted) {
        tweet.retweeted = NO;
        [sender setSelected:NO];
        [self.twitterAPI accessTwitterAPI:RETWEET_DESTROY parameters:@{@"id":tweet.retweetId}];
    } else {
        tweet.retweeted = YES;
        [sender setSelected:YES];
        [self.twitterAPI accessTwitterAPI:POST_RETWEET parameters:@{@"id":tweet.tweetId}];
    }
    [self retweetStatusChanged:tweet];

}
-(void)favoriteButtonPressed:(UIButton *)sender
{
    TweetCell *tweetCell = (TweetCell *)sender.superview.superview.superview;
    Tweet *tweet = tweetCell.tweet;
    if (tweet.favorited) {
        tweet.favorited = NO;
        [sender setSelected:NO];
        [self.twitterAPI accessTwitterAPI:FAVORITES_DESTROY parameters:@{@"id": tweet.tweetId}];
    } else {
        tweet.favorited = YES;
        [sender setSelected:YES];
        [self.twitterAPI accessTwitterAPI:FAVORITES_CREATE parameters:@{@"id": tweet.tweetId}];
    }
    [self favoriteStatusChanged:tweet];
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.spinner startAnimating];
    [self.twitterAPI accessTwitterAPI:HOME_TIMELINE parameters:nil];
}

#pragma mark - TwitterApi
- (void)twitterDidReturn:(NSArray *)data operation:(TwitterOperation)operation errorMessage:(NSString *)errorMessage
{
    if (self.spinner.isAnimating) {
        [self.spinner stopAnimating];
    }
    
    if ([data isKindOfClass:[NSDictionary class]] && ((NSDictionary *)data)[@"errors"][0][@"message"]) {
        // Happens when we hit our API Rate Limit.
        NSString *rateLimitMessage = ((NSDictionary *)data)[@"errors"][0][@"message"];
        NSLog(@"TwitterDidReturn with error.");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:rateLimitMessage
                                              message:@"Try again in a few minutes." delegate:self
                                              cancelButtonTitle:@"Retry"
                                              otherButtonTitles:nil, nil
        ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
        return;
    }
    
    if (errorMessage) {
        self.isAuthenticated = NO;
        NSLog(@"TwitterDidReturn with error.");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Setup Error"
                                              message:errorMessage delegate:self
                                              cancelButtonTitle:@"Retry"
                                              otherButtonTitles:nil, nil
        ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
    } else {
        self.isAuthenticated = YES;
        
        switch (operation) {
                
            case HOME_TIMELINE: {
                self.dataFromTwitter = [[NSMutableArray alloc] initWithArray:data];
                NSMutableArray *newTweets = [[NSMutableArray alloc] init];
                for (NSDictionary *dict in data) {
                    Tweet *tweet = [[Tweet alloc] initWithDictionary:dict];
                    [newTweets addObject:tweet];
                }
                self.tweets = newTweets;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
                break;
            }
                
            case SHOW_CURRENT_USER: {
                NSLog(@"Done getting current user data.");
                self.currentUserInfo = [[Tweet alloc] initWithDictionary:@{@"user": data}];
                break;
            }
                
            case POST_TWEET: {
                NSLog(@"Done posting tweet.");
                break;
            }
                
            case POST_RETWEET: {
                NSLog(@"Done posting retweet.");
                NSDictionary *dict = (NSDictionary *)data;
                NSString *retweet_id = dict[@"id_str"];
                NSString *original_id = dict[@"retweeted_status"][@"id_str"];
                for (Tweet *t in self.tweets) {
                    if ([t.tweetId isEqualToString:original_id]) {
                        t.retweetId = retweet_id;
                        break;
                    }
                }
                break;
            }
                
                
            case RETWEET_DESTROY: {
                NSLog(@"Done deleting retweet.");
                break;
            }
                
            default:
                NSLog(@"TwitterDidReturn with unknown operation: %i", operation);
                break;
        }
    }
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.isAuthenticated) {
        return 1;
    }
    
    if (!self.tweets) {
        return 0;
    }
    
    return [self.tweets count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isAuthenticated) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        self.spinner.center = cell.center;
        [cell addSubview:self.spinner];
        [self.spinner startAnimating];
        return cell;
    }
    
    TweetCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TweetCell" forIndexPath:indexPath];
    Tweet *tweet = [self.tweets objectAtIndex:indexPath.row];
    cell = [cell initWithTweet:tweet];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.tweets count] == 0) {
        return 180;
    }
    Tweet *tweet = self.tweets[indexPath.row];
    if (tweet.tweetImageURL) {
        return 180;         // Height of prototype cell, with tweetImage.
    } else {
        return 180 - 86;    // Above minus the height of the tweetImage.
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

-(void)favoriteStatusChanged:(Tweet *)tweet
{
    for (Tweet *t in self.tweets) {
        if ([t isEqual:tweet]) {
            t.favorited = tweet.favorited;
            [self.tableView reloadData];
            break;
        }
    }
    
}

-(void)retweetStatusChanged:(Tweet *)tweet
{
    for (Tweet *t in self.tweets) {
        if ([t isEqual:tweet]) {
            t.retweeted = tweet.retweeted;
            [self.tableView reloadData];
            break;
        }
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showTweet"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Tweet *tweet = self.tweets[indexPath.row];
        TweetViewController *tvc = (TweetViewController *)segue.destinationViewController;
        tvc.tweet = tweet;
        tvc.timelineViewController = self;
        [segue.destinationViewController setCurrentUserInfo:self.currentUserInfo];
    } else if ([segue.identifier isEqualToString:@"showCompose"]) {
        [segue.destinationViewController setCurrentUserInfo:self.currentUserInfo];
        [segue.destinationViewController setReplyTo:nil];
        [segue.destinationViewController setDelegate:self];
    } else if ([segue.identifier isEqualToString:@"showComposeWithReply"]) {
        UIButton *replyButton = (UIButton *)sender;
        TweetCell *tweetCell = (TweetCell *)replyButton.superview.superview.superview;
        [segue.destinationViewController setCurrentUserInfo:self.currentUserInfo];
        [segue.destinationViewController setReplyTo:tweetCell.tweet];
        [segue.destinationViewController setDelegate:self];
    } else {
        NSLog(@"Unrecognized segue.identifier: %@", segue.identifier);
    }
}

#pragma mark - ComposeViewControllerDelegate
-(void)composeViewControllerDidFinish:(ComposeViewController *)controller
{
    ComposeViewController *cvc = (ComposeViewController *)controller;
    if (cvc.tweetText) {
        Tweet *newTweet = self.currentUserInfo;
        newTweet.tweet = cvc.tweetText;
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        // Sun Jan 26 10:33:03 +0000 2014
        [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
        newTweet.timestamp = [df stringFromDate:[NSDate date]];
        [self.tweets insertObject:newTweet atIndex:0];
        [self.tableView reloadData];
        
        if (cvc.replyTo) {
            NSDictionary *parameters = @{@"status": newTweet.tweet,
                           @"in_reply_to_status_id": cvc.replyTo.tweetId};
            [self.twitterAPI accessTwitterAPI:POST_TWEET parameters:parameters];
        } else {
            NSDictionary *parameters = @{@"status": newTweet.tweet};
            [self.twitterAPI accessTwitterAPI:POST_TWEET parameters:parameters];
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Inifinite scrooooooooooooooooooollllliiiiiiiinnnnnnnnnngggggggg........
    CGFloat actualPosition = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height - 500;
    NSString *count = [NSString stringWithFormat:@"%i", [self.tweets count] + 20];
    if (!self.lastScroll) {
        self.lastScroll = 0;
    }
    if (self.lastScroll < actualPosition - 500 && actualPosition >= contentHeight) {
        self.lastScroll = actualPosition;
        [self.twitterAPI accessTwitterAPI:HOME_TIMELINE parameters:@{@"count":count}];
    }
}

@end

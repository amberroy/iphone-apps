//
//  DetailViewController.m
//  TwitterClone
//
//  Created by Amber Roy on 1/23/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "TweetViewController.h"
#import "UIImageView+AFNetworking.h"

@interface TweetViewController ()
- (void)configureView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *tweetLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tweetImage;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UILabel *retweetsLabel;
@property (weak, nonatomic) IBOutlet UILabel *favoritesLabel;

@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@property (weak, nonatomic) IBOutlet UIButton *retweetButton;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;

@property TwitterAPI *twitterAPI;

@end

@implementation TweetViewController

- (IBAction)retweet:(id)sender
{
    if (self.tweet.retweeted) {
        self.tweet.retweeted = NO;
        self.retweetsLabel.text = [NSString stringWithFormat:@"%i", --self.tweet.retweets];
        [self.retweetButton setSelected:NO];
        [self.twitterAPI accessTwitterAPI:RETWEET_DESTROY parameters:@{@"id": self.tweet.retweetId}];
    } else {
        self.tweet.retweeted = YES;
        self.retweetsLabel.text = [NSString stringWithFormat:@"%i", ++self.tweet.retweets];
        [self.retweetButton setSelected:YES];
        [self.twitterAPI accessTwitterAPI:POST_RETWEET parameters:@{@"id": self.tweet.tweetId}];
    }
    [self.timelineViewController retweetStatusChanged:self.tweet];
}

- (IBAction)favorite:(id)sender
{
    if (self.tweet.favorited) {
        self.tweet.favorited = NO;
        self.favoritesLabel.text = [NSString stringWithFormat:@"%i", --self.tweet.favorites];
        [self.favoriteButton setSelected:NO];
        [self.twitterAPI accessTwitterAPI:FAVORITES_DESTROY parameters:@{@"id": self.tweet.tweetId}];
    } else {
        self.tweet.favorited = YES;
        self.favoritesLabel.text = [NSString stringWithFormat:@"%i", ++self.tweet.favorites];
        [self.favoriteButton setSelected:YES];
        [self.twitterAPI accessTwitterAPI:FAVORITES_CREATE parameters:@{@"id": self.tweet.tweetId}];
    }
    [self.timelineViewController favoriteStatusChanged:self.tweet];
}

#pragma mark - Managing the detail item

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.tweet) {
        self.nameLabel.text = self.tweet.name;
        self.usernameLabel.text = [NSString stringWithFormat:@"@%@", self.tweet.username];
        self.userImage.image = self.tweet.userImage;
        self.tweetLabel.text = self.tweet.tweet;
        self.retweetsLabel.text = [NSString stringWithFormat:@"%i", self.tweet.retweets];
        self.favoritesLabel.text = [NSString stringWithFormat:@"%i", self.tweet.favorites];
      
        
        self.retweetButton.selected = (self.tweet.retweeted) ? YES : NO;
        self.favoriteButton.selected = (self.tweet.favorited) ? YES : NO;
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];// Sun Jan 26 10:33:03 +0000 2014
        NSDate *date = [df dateFromString:self.tweet.timestamp];
        [df setDateFormat:@"M/d/yy, HH:mm a"];              // 1/26/14, 10:33 AM
        self.timestampLabel.text = [df stringFromDate:date];
        
        [self.tweetImage setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:self.tweet.tweetImageURL]
                               placeholderImage:nil success:
         ^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
             self.tweetImage.image = image;
             self.tweetImage.contentMode = UIViewContentModeScaleToFill;
             [self.tweetImage setNeedsLayout];
         }
        failure:^(NSURLRequest *req, NSHTTPURLResponse *res, NSError *error) {
            NSLog(@"Failed to load Tweet image at URL: %@\nerror:%@", self.tweet.tweetImageURL, error);
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.twitterAPI) {
        self.twitterAPI = [[TwitterAPI alloc] init];
        self.twitterAPI.delegate = self;
    }
    
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showComposeWithReply"]) {
        [segue.destinationViewController setReplyTo:self.tweet];
        [segue.destinationViewController setDelegate:self.timelineViewController];
        [segue.destinationViewController setCurrentUserInfo:self.currentUserInfo];
    }
}

#pragma mark - TwitterAPIDelegate
-(void)twitterDidReturn:(NSArray *)data operation:(TwitterOperation)operation errorMessage:(NSString *)errorMessage
{
    // No action needed. 
}

@end

//
//  TweetCell.m
//  TwitterClone
//
//  Created by Amber Roy on 1/23/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "TweetCell.h"
#import "Tweet.h"
#import "TimelineViewController.h"
#import "UIImageView+AFNetworking.h"

@interface TweetCell ()

@property (weak) Tweet *tweet;

@end

@implementation TweetCell

- (TweetCell *)initWithTweet:(Tweet *)tweet
{
    self.tweet = tweet;
    self.nameLabel.text = tweet.name;
    self.usernameLabel.text = [NSString stringWithFormat:@"@%@", tweet.username];
    self.userImage.image = tweet.userImage;
    self.tweetLabel.text = tweet.tweet;
    
    // Set up buttons.
    UITableView *tv = (UITableView *) self.superview.superview;
    TimelineViewController *vc = (TimelineViewController *) tv.dataSource;
    [self.replyButton addTarget:vc action:@selector(replyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.retweetButton addTarget:vc action:@selector(retweetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.favoriteButton addTarget:vc action:@selector(favoriteButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // Asynchronous loading of tweet image, if we have one.
    __weak TweetCell *weakCell = self; // Use weak ref in callback.
    [self.tweetImage setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:tweet.tweetImageURL]
        placeholderImage:nil success:
        ^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakCell.tweetImage.image = image;
            weakCell.tweetImage.contentMode = UIViewContentModeScaleToFill;
            [weakCell setNeedsLayout];
        }
        failure:^(NSURLRequest *req, NSHTTPURLResponse *res, NSError *error) {
            NSLog(@"Failed to load Tweet image at URL: %@\nerror:%@", tweet.tweetImageURL, error);
        }];
    
    return self;
}

- (TweetCell *)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

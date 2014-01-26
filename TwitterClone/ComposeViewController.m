//
//  ComposeViewController.m
//  TwitterClone
//
//  Created by Amber Roy on 1/25/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "ComposeViewController.h"

@interface ComposeViewController ()

// Following are for the current user, who is composing the tweet.
@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UITextView *tweetField;

@end

@implementation ComposeViewController

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
    
	// Do any additional setup after loading the view.
    self.nameLabel.text = self.senderName;
    self.usernameLabel.text = self.senderUsername;
    self.userImage.image = self.senderImage;
    
    // Start the tweet with @recipient
    if (self.replyTo) {
        self.tweetField.text = [NSString stringWithFormat:@"@%@ ", self.replyTo];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneCompose:(id)sender {
    // TODO
    NSLog(@"Tweet not yet implemented");
    [self.delegate composeViewControllerDidFinish:self];
}

- (IBAction)cancelCompose:(id)sender {
    [self.delegate composeViewControllerDidFinish:self];
}

@end

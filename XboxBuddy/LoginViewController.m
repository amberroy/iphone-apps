//
//  LoginViewController.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/17/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@property (strong, nonatomic) IBOutlet UITextField *gamerTag;

- (IBAction)login:(id)sender;

@end

@implementation LoginViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender {
    // TODO: add some validation on gamer tag here and insert errors
    // Fetch data from Xbox Live.
    //NSString *sampleGamertag = [XboxLiveClient gamertagsForTesting][0];
    XboxLiveClient *xboxLiveClient = [XboxLiveClient instance];
    
    xboxLiveClient.isOfflineMode = YES;   // USE LOCAL DATA INSTEAD FETCHING FROM API
    [xboxLiveClient initWithGamertag:self.gamerTag.text completion: ^(NSString *errorMessage) {
        if (errorMessage) {
            NSLog(@"Failed to initialize XboxLiveClient: %@", errorMessage);
        } else {
            NSLog(@"XboxLiveClient initialization complete.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"InitialDataLoaded"
                                                                object:nil
                                                              userInfo:nil];
        }
    }];
    
    [User setCurrentUser:[[User alloc] initWithGamerTag:self.gamerTag.text]];
}
@end

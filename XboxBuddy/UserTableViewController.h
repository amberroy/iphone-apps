//
//  UserTableViewController.h
//  XboxBuddy
//
//  Created by Christine Wang on 2/4/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "Profile.h"

@interface UserTableViewController : UITableViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) Profile *profile;

@end

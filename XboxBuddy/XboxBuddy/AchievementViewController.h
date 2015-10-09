//
//  AchievementViewController.h
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "Achievement.h"

@interface AchievementViewController : UIViewController <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) Achievement *achievement;
@property (nonatomic, assign) BOOL focusCommentTextField;

-(void)deleteButtonPressed:(UIButton *)sender;

@end

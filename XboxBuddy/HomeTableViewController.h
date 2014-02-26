//
//  HomeTableViewController.h
//  XboxBuddy
//
//  Created by Christine Wang on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeTableViewController : UITableViewController

+(void)customizeNavigationBar:(UIViewController *)viewController;

@property Achievement *achievementForModal;

@end

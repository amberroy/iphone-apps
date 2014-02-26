//
//  AppDelegate.h
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// Handle special case where app launches from Push Notification.
@property BOOL didLaunchWithNotification;
@property NSDictionary *notificationPayload;

@end

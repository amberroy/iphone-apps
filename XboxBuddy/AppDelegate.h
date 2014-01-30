//
//  AppDelegate.h
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XboxLiveAPI.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, XboxLiveAPIDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

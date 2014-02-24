//
//  AppDelegate.m
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "AppDelegate.h"
#import "SignedOutViewController.h"
#import "Comment.h"
#import "ParseClient.h"
#import "XboxLiveClient.h"
#import <Parse/Parse.h>

@interface AppDelegate ()

@property (nonatomic, strong) SignedOutViewController *signedOutViewController;
@property (nonatomic, strong) UITabBarController *tabBarViewController;
@property (nonatomic, strong) UIViewController *currentVC;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    XboxLiveClient.isOfflineMode = YES;    // USE LOCAL DATA INSTEAD FETCHING FROM API
    
    // Add observers for notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin) name:UserDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogout) name:UserDidLogoutNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xboxLiveClientDidInit) name:@"InitialDataLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xboxLiveClientDidInit) name:XboxLiveClientDidInitNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parseClientDidInit) name:ParseClientDidInitNotification object:nil];
    
    // Add Parse keys.
    [Comment registerSubclass];
    [Like registerSubclass];
    [Parse setApplicationId:@"XBQ1N1MT6o7rz71junys5aguU8vlJ8J5mCjUbVE9"
                  clientKey:@"Ychj0QYNppyWNBFD9GUJoFE8AxhEldW75hoNdwff"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.currentVC;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Private methods


- (UIViewController *)currentVC {    
    if ([User currentUser]) {
        return self.tabBarViewController;
    } else {
        return self.signedOutViewController;
    }
}

- (UITabBarController *)tabBarViewController {
    if (!_tabBarViewController) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _tabBarViewController = [storyboard instantiateViewControllerWithIdentifier:@"TabBarViewController"];
    }
    
    return _tabBarViewController;
}

- (SignedOutViewController *)signedOutViewController {
   // if (!_signedOutViewController) {
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _signedOutViewController = [storyboard instantiateViewControllerWithIdentifier:@"SignedOutViewController"];
    //}
    
    return _signedOutViewController;
}

- (void)userDidLogin {
    self.window.rootViewController = self.currentVC;
    [[XboxLiveClient instance] initInstance];
}

- (void)userDidLogout {
    self.window.rootViewController = self.currentVC;
    [XboxLiveClient resetInstance];
    [ParseClient resetInstance];
    
    // Reset to first tab.
    self.tabBarViewController.selectedIndex = 0;
}

- (void)xboxLiveClientDidInit
{
    // Now init the ParseClient.
    XboxLiveClient *xlc = [XboxLiveClient instance];
    [[ParseClient instance] initInstance:xlc.userProfile withProfiles:xlc.friendProfiles];
}

- (void)parseClientDidInit
{
    // Initial data loaded, post notification so controllers can reload tables.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"InitialDataLoaded" object:nil];
}


@end

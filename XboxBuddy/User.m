//
//  User.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/17/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "User.h"

NSString * const UserDidLoginNotification = @"UserDidLoginNotification";
NSString * const UserDidLogoutNotification = @"UserDidLogoutNotification";
NSString * const kCurrentUserKey = @"kCurrentUserKey";

@implementation User

static BOOL isOfflineMode = YES;    // USE LOCAL DATA INSTEAD FETCHING FROM API

static User *_currentUser;

+ (User *)currentUser {
    if (!_currentUser) {
        NSString *gamerTag = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentUserKey];
        if (gamerTag) {
            _currentUser = [[User alloc] initWithGamerTag:gamerTag]; // Needs to be set before calling initInstance.
            [[XboxLiveClient instance] initInstance];
        }
    }
    return _currentUser;
}

+ (void)setCurrentUser:(User *)currentUser {
    if (currentUser) {
        [[NSUserDefaults standardUserDefaults] setObject:currentUser.gamerTag forKey:kCurrentUserKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentUserKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (!_currentUser && currentUser) {
        _currentUser = currentUser; // Needs to be set before firing the notification
        [[NSNotificationCenter defaultCenter] postNotificationName:UserDidLoginNotification object:nil];
    } else if (_currentUser && !currentUser) {
        _currentUser = currentUser; // Needs to be set before firing the notification
        [[NSNotificationCenter defaultCenter] postNotificationName:UserDidLogoutNotification object:nil];
    }
}

+ (BOOL) isOfflineMode
{
    return isOfflineMode;
}
+ (void) setIsOfflineMode:(BOOL)newVal
{
    isOfflineMode = newVal;
}


- (id)initWithGamerTag:(NSString *)gamerTag {
    self = [super init];
    if (self) {
        self.gamerTag = gamerTag;
    }
    return self;
}

@end

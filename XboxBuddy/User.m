//
//  User.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/17/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "User.h"
#import <Parse/Parse.h>

NSString * const UserDidLoginNotification = @"UserDidLoginNotification";
NSString * const UserDidLogoutNotification = @"UserDidLogoutNotification";
NSString * const kCurrentUserKey = @"kCurrentUserKey";

@implementation User

static User *_currentUser;

+ (User *)currentUser {
    if (!_currentUser) {
        NSString *gamerTag = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentUserKey];
        if (gamerTag) {
            _currentUser = [[User alloc] initWithGamerTag:gamerTag]; // Needs to be set before calling initInstance.
            [[XboxLiveClient instance] initInstance];
            
            if ([User currentUser].gamerTag) {
                PFInstallation *currentInstallation = [PFInstallation currentInstallation];
                [currentInstallation setObject:[User currentUser].gamerTag forKey:@"gamertag"];
                if (currentInstallation.badge != 0) {
                    // We're not using badges right now but this is the place to clear it.
                    currentInstallation.badge = 0;
                }
                [currentInstallation saveEventually];
                NSLog(@"Registering this Parse Installation to gamertag %@", [User currentUser].gamerTag);
            }
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

- (id)initWithGamerTag:(NSString *)gamerTag {
    self = [super init];
    if (self) {
        self.gamerTag = gamerTag;
    }
    return self;
}

@end

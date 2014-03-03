//
//  User.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/17/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "User.h"
#import "ParseClient.h"
#import <Parse/Parse.h>
#import <Parse/PFObject+Subclass.h>

NSString * const UserDidLoginNotification = @"UserDidLoginNotification";
NSString * const UserDidLogoutNotification = @"UserDidLogoutNotification";
NSString * const kCurrentUserKey = @"kCurrentUserKey";

@implementation User

@dynamic gamertag;

static User *_currentUser;

+ (User *)currentUser {
    if (!_currentUser) {
        NSString *gamerTag = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentUserKey];
        if (gamerTag) {
            _currentUser = [[User alloc] initWithGamerTag:gamerTag]; // Needs to be set before calling initInstance.
            [[XboxLiveClient instance] initInstance];
            [[ParseClient instance] registerInstallation];
        }
    }
    return _currentUser;
}

+ (void)setCurrentUser:(User *)currentUser {
    if (currentUser) {
        [[NSUserDefaults standardUserDefaults] setObject:currentUser.gamertag forKey:kCurrentUserKey];
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
        self.gamertag = gamerTag;
    }
    return self;
}

+ (NSString *)parseClassName
{
    return @"User";
}

@end

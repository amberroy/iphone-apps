//
//  User.h
//  XboxBuddy
//
//  Created by Christine Wang on 2/17/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFSubclassing.h>
#import <Parse/PFObject.h>

extern NSString *const UserDidLoginNotification;
extern NSString *const UserDidLogoutNotification;

@interface User : PFObject <PFSubclassing>

+ (User *)currentUser;
+ (void)setCurrentUser:(User *)currentUser;

- (id)initWithGamerTag:(NSString *)gamertag;

@property (nonatomic, strong) NSString *gamertag;

@end

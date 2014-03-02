//
//  Invitation.m
//  XboxBuddy
//
//  Created by Amber Roy on 3/1/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "Invitation.h"
#import <Parse/PFObject+Subclass.h>

@implementation Invitation

@dynamic senderGamertag;
@dynamic recipientGamertag;
@dynamic dateSent;

- (Invitation *)initWithRecipient:(NSString *)gamertag
{
    self = [super init];
    if (self) {
        self.recipientGamertag = gamertag;
        self.senderGamertag = [User currentUser].gamerTag;
        self.dateSent = [NSDate date];
    }
    return self;
}

+ (NSString *)parseClassName
{
    return @"Invitation";
}

@end

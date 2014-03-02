//
//  Invitation.h
//  XboxBuddy
//
//  Created by Amber Roy on 3/1/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/PFSubclassing.h>
#import <Parse/PFObject.h>

@interface Invitation : PFObject <PFSubclassing>

@property NSString *senderGamertag;
@property NSString *recipientGamertag;
@property NSDate *dateSent;

- (Invitation *)initWithRecipient:(NSString *)gamertag;

@end

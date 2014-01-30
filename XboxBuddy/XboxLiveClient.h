//
//  XboxLiveAPI.h
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XboxLiveClient;

@interface XboxLiveClient : NSObject

@property NSString *currentUserGamertag;
@property NSDictionary *currentUserProfile;

+(XboxLiveClient*)instance;

-(void)initWithGamertag:(NSString *)currentUserGamertag
             completion:(void (^)(NSString *errorDescription))completion;

@end

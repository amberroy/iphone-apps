//
//  XboxLiveAPI.h
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XboxLiveAPI;

@protocol XboxLiveAPIDelegate

typedef enum {
    XboxLiveProfile,
} XboxLiveOperation;

- (void)xboxLiveDidReturn:(NSArray *)data operation:(XboxLiveOperation)operation errorMessage:(NSString *)errorMessage;
@end

@interface XboxLiveAPI : NSObject

@property (weak, nonatomic) id <XboxLiveAPIDelegate> delegate;
@property NSString *current_username;


- (void)accessXboxLiveAPI:(XboxLiveOperation)operation parameters:(NSDictionary *)parameters;


@end

//
//  XboxLiveAPI.m
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "XboxLiveClient.h"

@interface XboxLiveClient ()

@property (nonatomic, copy) void (^completionBlock)(NSString *errorDescription);

@property NSMutableArray *pendingRequests;
@property BOOL isInitializationError;

-(void)sendRequestWithURL:(NSURL *)url success:(void(^)(NSDictionary *responseDictionary))success;
-(void)checkPendingRequests;

-(void)processProfileResponse:(NSDictionary *)responseData;
-(void)processFriendsResponse:(NSDictionary *)responseData;

@end

@implementation XboxLiveClient

+(XboxLiveClient *)instance
{
    static dispatch_once_t once;
    static XboxLiveClient *instance;
    
    dispatch_once(&once, ^{
        instance = [[XboxLiveClient alloc] init];
    });
    
    return instance;
}

-(void)initWithGamertag:(NSString *)currentUserGamertag
             completion:(void (^)(NSString *errorDescription))completion
{
    self.currentUserGamertag = currentUserGamertag;
    self.completionBlock = completion;
    self.pendingRequests = [[NSMutableArray alloc] init];
    self.isInitializationError = NO;
    
    // Send Profile request.
    NSString *profile_url_str = [NSString stringWithFormat:
                                 @"http://xboxleaders.com/api/profile.json?gamertag=%@",
                                 self.currentUserGamertag];
    NSURL *profile_url = [NSURL URLWithString:profile_url_str];
    [self sendRequestWithURL:profile_url
                  success:^(NSDictionary *responseData) {
                      [self processProfileResponse:responseData];
                  }];
    
    // Send Friends request.
    NSString *friends_url_str = [NSString stringWithFormat:
                                 @"http://xboxleaders.com/api/friends.json?gamertag=%@",
                                 self.currentUserGamertag];
    NSURL *friends_url = [NSURL URLWithString:friends_url_str];
    [self sendRequestWithURL:friends_url
                  success:^(NSDictionary *responseData) {
                      [self processFriendsResponse:responseData];
                  }];
    
}

-(void)checkPendingRequests
{
    if ([self.pendingRequests count] == 0) {
    
        // All requests complete, notify caller.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(nil);
        });
    }
}

-(void)processProfileResponse:(NSDictionary *)responseData
{
    self.profile = responseData;
    self.currentUserGamertag = responseData[@"gamertag"];
}

-(void)processFriendsResponse:(NSDictionary *)responseData
{
    self.friends = responseData;
    
    // TODO: Fetch achievements for games in each friend's Recent Activity list.
}

-(void)sendRequestWithURL:(NSURL *)url success:(void(^)(NSDictionary *responseDictionary))success
{
    NSString *myRequestKey = [url absoluteString];
    [self.pendingRequests addObject:myRequestKey];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"Sending request: %@", url);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *urlResponse, NSData *responseData, NSError *connectionError)
     {
         NSString *errorMessage = nil;
         NSDictionary *myResponseDictionary = nil;
         if (connectionError) {
             errorMessage = [NSString stringWithFormat:@"ERROR connecting to %@", url];
         } else {
             
             NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
             if (!response) {
                 errorMessage = [NSString stringWithFormat:@"Empty response from %@", url];
             } else {
                 if ([response[@"status"] isEqualToString:@"error"]) {
                     errorMessage = response[@"data"][@"message"];
                 } else {
                     NSLog(@"Request successful. Freshness: '%@'  Runtime: %@",
                           response[@"data"][@"freshness"], response[@"runtime"]);
                     //[XboxLiveClient instance].currentUserProfile = response[@"data"];
                     myResponseDictionary = response[@"data"];
                 }
             }
         }
         if (errorMessage) {
             NSLog(@"Request failed at %@: %@", myRequestKey, errorMessage);
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.completionBlock(errorMessage);
             });
         } else {
             
             success(myResponseDictionary);
             [self.pendingRequests removeObject:myRequestKey];
             [self checkPendingRequests];
         }
     }];
    
}

@end









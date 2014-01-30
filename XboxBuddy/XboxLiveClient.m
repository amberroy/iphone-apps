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

-(void)sendRequestWithURL:(NSURL *)url completion:(void(^)(NSDictionary *responseDictionary, NSString *errorMessage))completion;

-(void)processProfileResponse:(NSDictionary *)responseData errorMessage:(NSString *)errorMessage;

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
    
    // Send Profile request.
    NSString *profile_url_str = [NSString stringWithFormat:
                                 @"http://xboxleaders.com/api/profile.json?gamertag=%@",
                                 self.currentUserGamertag];
    NSURL *profile_url = [NSURL URLWithString:profile_url_str];
    [self sendRequestWithURL:profile_url
                  completion:^(NSDictionary *responseData, NSString *errorMessage) {
                      [self processProfileResponse:responseData errorMessage:errorMessage];
                  }];
    
    
}

-(void)processProfileResponse:(NSDictionary *)responseData errorMessage:(NSString *)errorMessage
{
    if (errorMessage) {
        NSLog(@"Failed to get Profile: %@", errorMessage);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(errorMessage);
        });
        return;
    }
    
    self.currentUserProfile = responseData;
    self.currentUserGamertag = responseData[@"gamertag"];
    
    // Initialization complete.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completionBlock(nil);
    });
}

-(void)sendRequestWithURL:(NSURL *)url completion:(void(^)(NSDictionary *responseDictionary, NSString *errorMessage))completion
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"Sending request: %@", url);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *urlResponse, NSData *responseData, NSError *connectionError)
     {
         NSString *myErrorMessage = nil;
         NSDictionary *myResponseDictionary = nil;
         if (connectionError) {
             myErrorMessage = [NSString stringWithFormat:@"ERROR connecting to %@", url];
         } else {
             
             NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
             if (!response) {
                 myErrorMessage = [NSString stringWithFormat:@"Empty response from %@", url];
             } else {
                 if ([response[@"status"] isEqualToString:@"error"]) {
                     myErrorMessage = response[@"data"][@"message"];
                 } else {
                     NSLog(@"Request successful. Freshness: '%@'  Runtime: %@",
                           response[@"data"][@"freshness"], response[@"runtime"]);
                     //[XboxLiveClient instance].currentUserProfile = response[@"data"];
                     myResponseDictionary = response[@"data"];
                 }
             }
         }
         completion(myResponseDictionary, myErrorMessage);
     }];
    
}

@end









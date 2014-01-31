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

@property NSDate *startInit;
@property NSDate *endInit;
@property NSTimeInterval secondsToInit;

-(void)sendRequestWithURL:(NSString *)url retries:(int)retries success:(void(^)(NSDictionary *responseDictionary))success;
-(void)checkPendingRequests;

-(void)processProfile:(NSDictionary *)responseData;
-(void)processFriends:(NSDictionary *)responseData;

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

-(void)initWithGamertag:(NSString *)userGamertag
             completion:(void (^)(NSString *errorDescription))completion
{
    self.userGamertag = userGamertag;
    self.completionBlock = completion;
    self.pendingRequests = [[NSMutableArray alloc] init];
    self.isInitializationError = NO;
    
    NSLog(@"XboxLiveClient initializing with %@", userGamertag);
    self.startInit = [NSDate date];
    
    // Send Friends request.
    NSString *friends_url_str = [NSString stringWithFormat:
                                 @"http://xboxapi.com/v1/friends/%@",
                                 self.userGamertag];
    [self sendRequestWithURL:friends_url_str retries:3
                  success:^(NSDictionary *responseData) {
                      [self processFriends:responseData];
                  }];
    
    
    // Send Profile request.
    NSString *profile_url_str = [NSString stringWithFormat:
                                 @"http://xboxapi.com/v1/profile/%@",
                                 self.userGamertag];
    [self sendRequestWithURL:profile_url_str retries:3
                  success:^(NSDictionary *responseData) {
                      [self processProfile:responseData];
                  }];
}

-(void)checkPendingRequests
{
    if (self.isInitializationError) {
        // Error already returned to caller.
        return;
    }
    
    if ([self.pendingRequests count] == 0) {
    
        self.endInit = [NSDate date];
        self.secondsToInit = [self.endInit timeIntervalSinceDate:self.startInit];
        NSLog(@"XboxLiveClient initialized (%0.f seconds)", self.secondsToInit);
        
        // All requests complete, notify caller.
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(nil);
        });
    }
}

-(void)processFriends:(NSDictionary *)responseData
{
    self.userFriends = responseData[@"Friends"];
    NSLog(@"Added %lu Friends for current user %@",
          (unsigned long)[self.userFriends count], responseData[@"Player"][@"Gamertag"]);
    
    for (NSDictionary *friend in self.userFriends) {
        
        // Get profiles for all my friends.
        NSString *friendGamertag = friend[@"GamerTag"];
        NSString *profile_url_str = [NSString stringWithFormat:
                                     @"http://xboxapi.com/v1/profile/%@",
                                     friendGamertag];
        [self sendRequestWithURL:profile_url_str retries:3
                      success:^(NSDictionary *responseData) {
                          [self processProfile:responseData];
                      }];
    }
}

-(void)processProfile:(NSDictionary *)responseData
{
    NSString *friendGamertag = responseData[@"Player"][@"Gamertag"];
    if ([friendGamertag isEqualToString:self.userGamertag]) {
        self.userProfile = responseData;
        NSLog(@"Added profile for current user %@", self.userGamertag);
    } else {
        [self.friendProfiles addObject:responseData];
        NSLog(@"Added profile for friend %@", friendGamertag);
    }
    
    // Get Acheivements for the Recent Games.
    if ([responseData[@"RecentGames"] isKindOfClass:[NSArray class]]) {
        NSArray *games = responseData[@"RecentGames"];
        for (NSDictionary *game in games) {
            //int achievementsEarned = [game[@"Progress"][@"Achievements"] integerValue];
            //if (achievementsEarned == 0) {
            //    continue;   // Skip games (or apps) with no achievements.
            //}
            NSString *acheivements_url_str = [NSString stringWithFormat:
                                              @"http://xboxapi.com/v1/achievements/%@/%@",
                                              game[@"ID"], friendGamertag];
            
            [self sendRequestWithURL:acheivements_url_str retries:3
                             success:^(NSDictionary *responseData) {
                                 [self processAchievements:responseData];
                             }];
        }
    } else {
        // User has game history hidden in their privacy settings.
        NSLog(@"Cannot view Games for %@: Privacy Settings Enabled", friendGamertag);
    }
}

-(void)processAchievements:(NSDictionary *)responseData
{
    int unlockedCount = 0;
    if ([responseData[@"Achievements"] isKindOfClass:[NSArray class]]) {
        NSArray *achievements = responseData[@"Achievements"];
        for (NSDictionary *achievement in achievements) {
    
            long earnedOn = [achievement[@"EarnedOn-UNIX"] integerValue];
            if (earnedOn != 0) {
                [self.achievements addObject:achievement];
                unlockedCount++;
            }
        }
    }
    NSLog(@"Added %i achievements for %@ for game %@", unlockedCount,
          responseData[@"Player"][@"Gamertag"], responseData[@"Game"][@"Name"]);
    
    if ([responseData[@"Player"][@"Gamertag"] isEqualToString:self.userGamertag]) {
        NSLog(@"%@", responseData);
    }
    
}

-(void)sendRequestWithURL:(NSString *)url retries:(int)retries success:(void(^)(NSDictionary *responseDictionary))success
{
    NSString *url_encoded = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; NSString *requestKey = url_encoded;
    [self.pendingRequests addObject:requestKey];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url_encoded]];
    NSLog(@"Sending request: %@", url_encoded);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *urlResponse, NSData *responseData, NSError *connectionError)
     {
         NSString *errorMessage = nil;
         NSDictionary *myResponseDictionary = nil;
         if (connectionError) {
             errorMessage = [NSString stringWithFormat:@"ERROR connecting to %@", url_encoded];
         } else {
             
             NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
             if (!response) {
                 errorMessage = [NSString stringWithFormat:@"Empty response from %@", url_encoded];
             } else {
                 BOOL isSuccess = [response[@"Success"] boolValue];
                 if (!isSuccess) {
                     errorMessage = response[@"Error"];
                 } else {
                     myResponseDictionary = response;
                 }
             }
         }
         if (errorMessage) {
             if (retries > 0) {
                 NSLog(@"Retring request for %@", url_encoded);
                 [self sendRequestWithURL:url retries:(retries-1) success:success];
             } else {
                 NSLog(@"Request failed at %@: %@", url_encoded, errorMessage);
                 self.isInitializationError = YES;
                 dispatch_async(dispatch_get_main_queue(), ^{
                     self.completionBlock(errorMessage);
                 });
             }
         } else {
             
             success(myResponseDictionary);
             [self.pendingRequests removeObject:requestKey];
             [self checkPendingRequests];
         }
     }];
    
}

// Unused since we now use the Recent Games list instead of fetching Games directly.
//-(void)processFriendGames:(NSDictionary *)responseData
//{
//    NSString *friendGamertag = responseData[@"Player"][@"Gamertag"];
//
//    if ([responseData[@"Games"] isKindOfClass:[NSDictionary class]]) {
//        // User has game history hidden in their privacy settings.
//        NSString *errorMessage = responseData[@"Games"][@"Error"];
//        NSLog(@"Cannot view Games for %@: %@", friendGamertag, errorMessage);
//        return;
//    }
//
//    NSArray *friendGames = responseData[@"Games"];
//    NSLog(@"Downloaded %i games for %@", [friendGames count], friendGamertag);
//
//    // Get Achievements for Recent Games.
//    int numberOfGames = 5;
//    for (NSDictionary *game in friendGames) {
//        if (numberOfGames == 0) {
//            break;
//        }
//
//        int achievementsEarned = [game[@"Progress"][@"Achievements"] integerValue];
//        if (achievementsEarned > 0) {
//            NSString *achievements_url_str = [NSString stringWithFormat:
//                                         @"http://xboxapi.com/v1/achievements/%@/%@",
//                                         game[@"ID"], friendGamertag];
//            [self sendRequestWithURL:achievements_url_str retries:3
//                          success:^(NSDictionary *responseData) {
//                              [self processAchievements:responseData];
//                          }];
//            numberOfGames--;
//        }
//    }
//}



@end









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

-(void)sendRequestWithURL:(NSString *)url retries:(int)retries success:(void(^)(NSDictionary *responseDictionary))success;
-(void)checkPendingRequests;

-(void)processProfile:(NSDictionary *)responseData;
-(void)processFriends:(NSDictionary *)responseData;
-(void)processFriendProfile:(NSDictionary *)responseData;

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
    
    NSLog(@"Initializing XboxLiveClient for %@", userGamertag);
    
    // Send Friends request.
    NSString *friends_url_str = [NSString stringWithFormat:
                                 //@"http://xboxleaders.com/api/friends.json?gamertag=%@",
                                 @"http://xboxapi.com/v1/friends/%@",
                                 self.userGamertag];
    [self sendRequestWithURL:friends_url_str retries:3
                  success:^(NSDictionary *responseData) {
                      [self processFriends:responseData];
                  }];
    
    
    // Send Profile request.
    NSString *profile_url_str = [NSString stringWithFormat:
                                 //@"http://xboxleaders.com/api/profile.json?gamertag=%@",
                                 @"http://xboxapi.com/v1/profile/%@",
                                 self.userGamertag];
    [self sendRequestWithURL:profile_url_str retries:3
                  success:^(NSDictionary *responseData) {
                      [self processProfile:responseData];
                  }];

    // Send Games request.
    NSString *games_url_str = [NSString stringWithFormat:
                                 //@"http://xboxleaders.com/api/games.json?gamertag=%@",
                                 @"http://xboxapi.com/v1/games/%@",
                                 self.userGamertag];
    [self sendRequestWithURL:games_url_str retries:3
                  success:^(NSDictionary *responseData) {
                      [self processGames:responseData];
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

-(void)processProfile:(NSDictionary *)responseData
{
    self.userProfile = responseData;
    //self.userGamertag = responseData[@"gamertag"];
    //NSLog(@"Added profile for current user %@", responseData[@"gamertag"]);
    
    self.userGamertag = responseData[@"Player"][@"Gamertag"];
    NSLog(@"Added Profile for current user %@", responseData[@"Player"][@"Gamertag"]);
}

-(void)processGames:(NSDictionary *)responseData
{
    //self.userGames = responseData[@"games"];
    //NSLog(@"Added games for current user %@", responseData[@"gamertag"]);
    
    self.userGames = responseData[@"Games"];
    NSLog(@"Added Games for current user %@", responseData[@"Player"][@"Gamertag"]);
    
    // Get my own Achievements.
    [self processFriendGames:responseData];
}

-(void)processFriends:(NSDictionary *)responseData
{
    //self.friends = responseData[@"friends"];
    
    self.userFriends = responseData[@"Friends"];
    NSLog(@"Added Friends for current user %@", responseData[@"Player"][@"Gamertag"]);
    
    for (NSDictionary *friend in self.userFriends) {
        
        // Get profiles for all my friends.
        NSString *profile_url_str = [NSString stringWithFormat:
                                     @"http://xboxapi.com/v1/profile/%@",
                                     friend[@"GamerTag"]];
        
        [self sendRequestWithURL:profile_url_str retries:3
                      success:^(NSDictionary *responseData) {
                          [self processFriendProfile:responseData];
                      }];
        
        // Get Games for all my friends.
        NSString *games_url_str = [NSString stringWithFormat:
                                     @"http://xboxapi.com/v1/games/%@",
                                     friend[@"GamerTag"]];
        
        [self sendRequestWithURL:games_url_str retries:3
                      success:^(NSDictionary *responseData) {
                          [self processFriendGames:responseData];
                      }];
    }
}

-(void)processFriendProfile:(NSDictionary *)responseData
{
    [self.friendProfiles addObject:responseData];
    //NSString *friendGamertag = responseData[@"gamertag"];
    NSString *friendGamertag = responseData[@"Player"][@"Gamertag"];
    NSLog(@"Added profile for friend %@", friendGamertag);
}

-(void)processFriendGames:(NSDictionary *)responseData
{
    //NSString *friendGamertag = responseData[@"gamertag"];
    //NSArray *friendGames = responseData[@"games"];
    
    NSString *friendGamertag = responseData[@"Player"][@"Gamertag"];
    
    if ([responseData[@"Games"] isKindOfClass:[NSDictionary class]]) {
        // User has game history hidden in their privacy settings.
        NSString *errorMessage = responseData[@"Games"][@"Error"];
        NSLog(@"Cannot view Games for %@: %@", friendGamertag, errorMessage);
        return;
    }
    
    NSArray *friendGames = responseData[@"Games"];
    NSLog(@"Downloaded %i games for %@", [friendGames count], friendGamertag);
    
    // Get Achievements for Recent Games.
    int numberOfGames = 5;
    for (NSDictionary *game in friendGames) {
        if (numberOfGames == 0) {
            break;
        }
        numberOfGames--;
        
        int achievementsEarned = [game[@"Progress"][@"Achievements"] integerValue];
        if (achievementsEarned > 0) {
            NSString *achievements_url_str = [NSString stringWithFormat:
                                         @"http://xboxapi.com/v1/achievements/%@/%@",
                                         game[@"ID"], friendGamertag];
            [self sendRequestWithURL:achievements_url_str retries:3
                          success:^(NSDictionary *responseData) {
                              [self processAchievements:responseData];
                          }];
        }
    }
}


-(void)processAchievements:(NSDictionary *)responseData
{
    int unlockedCount = 0;
    NSArray *achievements = responseData[@"Achievements"];
    for (NSDictionary *achievement in achievements) {
    
        int earnedOn = [achievement[@"EarnedOn-UNIX"] integerValue];
        if (earnedOn != 0) {
            [self.achievements addObject:achievement];
            unlockedCount++;
        } else {
            ;;
        }
    }
    NSLog(@"Added %i achievements for %@ for game %@", unlockedCount,
          responseData[@"Player"][@"Gamertag"], responseData[@"Game"]);
    
}

-(void)sendRequestWithURL:(NSString *)url retries:(int)retries success:(void(^)(NSDictionary *responseDictionary))success
{
    
    NSString *url_encoded = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *requestKey = url_encoded;
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
                 // XboxLeaders.com
                 //if ([response[@"status"] isEqualToString:@"error"]) {
                 //    errorMessage = response[@"data"][@"message"];
                 BOOL isSuccess = [response[@"Success"] boolValue];
                 if (!isSuccess) {
                     //errorMessage = response[@"data"][@"message"];
                     errorMessage = response[@"Error"];
                 } else {
                     // XboxLeaders.com
                     //NSLog(@"Request successful. Freshness: '%@'  Runtime: %@", response[@"data"][@"freshness"], response[@"runtime"]);
                     //myResponseDictionary = response[@"data"];

                     // XboxAPI.com
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

@end









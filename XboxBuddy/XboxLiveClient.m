//
//  XboxLiveAPI.m
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "XboxLiveClient.h"

@interface XboxLiveClient ()

// Interface methods return data from these properties.
@property NSString *userGamertag;
@property NSDictionary *userProfileFromJSON;
@property NSArray *friendProfilesFromJSON;
@property NSArray *achievementsFromJSON;

// Used internally during initialization.
@property NSMutableArray *pendingRequests;
@property BOOL isInitializationError;
@property BOOL isImageError;
@property NSMutableArray *achievementsUnsorted;
@property NSMutableArray *friendProfilesUnsorted;
@property NSDate *startInit;
@property NSDate *endInit;
@property NSTimeInterval secondsToInit;
@property int retriesDefault;

// Callback to the object that envoked our init method.
@property (nonatomic, copy) void (^completionBlock)(NSString *errorDescription);

// Only methods that sends requests to the remote Xbox Live API.
-(void)sendRequestWithURL:(NSString *)url retries:(int)retries success:(void(^)(NSDictionary *responseDictionary))success;
-(void)imageRequestWithURL:(NSString *)url retries:(int)retries success:(void(^)(NSString *savedImagePath))success;

// Methods that determine when initialization is complete.
-(void)checkSavedDataExists;
-(void)checkPendingRequests;
-(void)requestsDidComplete;

// Called from our async request completion block to handle received data.
-(void)processProfile:(NSDictionary *)responseData;
-(void)processFriends:(NSDictionary *)responseData;
-(void)processImage:(NSString *)savedImagePath;

// Helpers
-(NSString *)urlToFilename:(NSString *)url;

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

+(NSArray *)gamertagsForTesting
{
    return @[ @"ambroy",            // amberroy
              @"JGailor",           // friend with 10,000+ gamerscore in 100+ games
              @"MyRazzleDazzle",    // friend with 15+ friends
              ];
}

-(void)initWithGamertag:(NSString *)userGamertag
             completion:(void (^)(NSString *errorDescription))completion
{
    self.userGamertag = userGamertag;
    self.completionBlock = completion;
    self.pendingRequests = [[NSMutableArray alloc] init];
    self.achievementsUnsorted = [[NSMutableArray alloc] init];
    self.friendProfilesUnsorted = [[NSMutableArray alloc] init];
    self.isInitializationError = NO;
    self.retriesDefault = 3;
    
    if (self.isOfflineMode) {
        [self checkSavedDataExists];
    }
    
    NSLog(@"XboxLiveClient initializing %@with gamertag %@",
          (self.isOfflineMode) ? @"in OFFLINE MODE " : @"", userGamertag);
    self.startInit = [NSDate date];
    
    // Send Profile request.
    NSString *profile_url_str = [NSString stringWithFormat: @"http://xboxapi.com/v1/profile/%@", self.userGamertag];
    [self sendRequestWithURL:profile_url_str retries:self.retriesDefault
                  success:^(NSDictionary *responseData) {
                      [self processProfile:responseData];
                  }];
    
    // Send Friends request.
    NSString *friends_url_str = [NSString stringWithFormat: @"http://xboxapi.com/v1/friends/%@", self.userGamertag];
    [self sendRequestWithURL:friends_url_str retries:self.retriesDefault
                  success:^(NSDictionary *responseData) {
                      [self processFriends:responseData];
                  }];
    
}

-(void)checkSavedDataExists
{
    // Check saved data for user friend list only, assume if we have that we have the rest.
    NSString *friends_url_str = [NSString stringWithFormat: @"http://xboxapi.com/v1/friends/%@", self.userGamertag];
    NSString *requestKey = [friends_url_str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *savedDataPath = [NSString stringWithFormat:@"%@/XboxLiveClient-%@.json", docsDir, [self urlToFilename:requestKey]];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:savedDataPath];
    if (!fileExists) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"No Saved Data Found"
                              message:@"Overriding Offline Mode for this run."
                              delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        NSLog(@"No Saved Data found at %@", savedDataPath);
        NSLog(@"Overriding OFFLINE MODE for this run.");
        self.isOfflineMode = NO;
        [alert show];
    } else {
        NSLog(@"Saved Data found at %@", savedDataPath);
    }
}


-(void)checkPendingRequests
{
    static dispatch_once_t once;
    
    if (self.isInitializationError) {
        // Error already returned to caller.
        return;
    }
    
    if ([self.pendingRequests count] == 0) {
        dispatch_once(&once, ^{
            // Avoid race condition where final two requests complete at the same time.
            [self requestsDidComplete];
        });
    }
}

-(void)requestsDidComplete
{
    // Sort achievements by date earned.
    self.achievementsFromJSON = [self.achievementsUnsorted sortedArrayUsingComparator:
         ^NSComparisonResult(id a, id b) {
               NSNumber *first_date = ((NSDictionary*)a)[@"Achievement"][@"EarnedOn-UNIX"];
               NSNumber *second_date = ((NSDictionary*)b)[@"Achievement"][@"EarnedOn-UNIX"];
               return [second_date compare:first_date];     // Descending.
         }];
        
    // Create list of friend gamertags, sorted by last achievement earned.
    NSMutableArray *gamertagArray = [[NSMutableArray alloc] init];
    for (NSDictionary *achievement in self.achievementsFromJSON) {
        NSString *gamertag = achievement[@"Player"][@"Gamertag"];
        if (![gamertagArray containsObject:gamertag]) {
            [gamertagArray addObject:gamertag];
        }
    }
    
    // Sort friends by last achievement earned.
    self.friendProfilesFromJSON = [self.friendProfilesUnsorted sortedArrayUsingComparator:
           ^NSComparisonResult(id a, id b) {
               NSString *first_gamertag = ((NSDictionary *)a)[@"Player"][@"Gamertag"];
               NSString *second_gamertag = ((NSDictionary *)b)[@"Player"][@"Gamertag"];
               
               // If friend doesn't have any achievements (or has hidden them with privacy settings)
               // then their gamertag won't be in the gamertagArray, so give them the highest index.
               NSNumber *first_index = [NSNumber numberWithLong:[gamertagArray count]];
               NSNumber *second_index = [NSNumber numberWithLong:[gamertagArray count]];
               if ([gamertagArray containsObject:first_gamertag]) {
                   first_index = [NSNumber numberWithLong:[gamertagArray indexOfObject:first_gamertag]];
               }
               if ([gamertagArray containsObject:second_gamertag]) {
                   second_index = [NSNumber numberWithLong:[gamertagArray indexOfObject:second_gamertag]];
               }
               return [first_index compare:second_index];
           }];
    
    self.endInit = [NSDate date];
    self.secondsToInit = [self.endInit timeIntervalSinceDate:self.startInit];
    int count = (int)[self.achievementsFromJSON count];
    NSLog(@"XboxLiveClient initialized %@for %@ with %i achievements (%0.f seconds)",
          (self.isOfflineMode) ? @"in OFFLINE MODE " : @"", self.userGamertag, count, self.secondsToInit);
    
    // Done, notify caller.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completionBlock(nil);
    });
}

-(void)processFriends:(NSDictionary *)responseData
{
    int count = (int)[responseData[@"Friends"] count];
    NSLog(@"Found %i Friends for current user %@", count, responseData[@"Player"][@"Gamertag"]);
    
    if (self.isInitializationError) {
        NSLog(@"Initialization error detected, skipping fetching friend profile.");
        return;
    }
    
    for (NSDictionary *friend in responseData[@"Friends"]) {
        
        // Get profiles for all my friends.
        NSString *friendGamertag = friend[@"GamerTag"];
        NSString *profile_url_str = [NSString stringWithFormat:
                                     @"http://xboxapi.com/v1/profile/%@",
                                     friendGamertag];
        [self sendRequestWithURL:profile_url_str retries:self.retriesDefault
                      success:^(NSDictionary *responseData) {
                          [self processProfile:responseData];
                      }];
    }
}

-(void)processProfile:(NSDictionary *)responseData
{
    NSString *friendGamertag = responseData[@"Player"][@"Gamertag"];
    if ([friendGamertag isEqualToString:self.userGamertag]) {
        self.userProfileFromJSON = responseData;
        NSLog(@"Added profile for current user %@", self.userGamertag);
    } else {
        [self.friendProfilesUnsorted addObject:responseData];
        NSLog(@"Added profile for friend %@", friendGamertag);
    }
    
    // Download avatar image.
    NSString *avatar_url_str = responseData[@"Player"][@"Avatar"][@"Body"];
    [self imageRequestWithURL:avatar_url_str retries:self.retriesDefault
                             success:^(NSString *savedImagePath) {
                                 [self processImage:savedImagePath];
                             }];
    
    if (self.isInitializationError) {
        NSLog(@"Initialization error detected, skipping fetching achievements.");
        return;
    }
    
    // Get Acheivements for the Recent Games.
    if ([responseData[@"RecentGames"] isKindOfClass:[NSArray class]]) {
        NSArray *games = responseData[@"RecentGames"];
        for (NSDictionary *game in games) {
            // This won't work because there's no Achievement Count in the recent games.
            //int achievementsEarned = [game[@"Progress"][@"Achievements"] integerValue];
            //if (achievementsEarned == 0) {
            //    continue;   // Skip games (or apps) with no achievements.
            //}
            NSString *acheivements_url_str = [NSString stringWithFormat:
                                              @"http://xboxapi.com/v1/achievements/%@/%@",
                                              game[@"ID"], friendGamertag];
            
            [self sendRequestWithURL:acheivements_url_str retries:self.retriesDefault
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
    NSString *gamertag = responseData[@"Player"][@"Gamertag"];
    int unlockedCount = 0;
    if ([responseData[@"Achievements"] isKindOfClass:[NSArray class]]) {
        
        NSArray *achievements = responseData[@"Achievements"];
        for (NSDictionary *achievement in achievements) {
    
            long earnedOn = [achievement[@"EarnedOn-UNIX"] integerValue];
            if (earnedOn != 0) {
                // Save the Player and Game info with the Achievement.
                [self.achievementsUnsorted addObject: @{@"Player": responseData[@"Player"],
                                                        @"Game": responseData[@"Game"],
                                                        @"Achievement": achievement}];
                unlockedCount++;
            }
        }
    }
    NSLog(@"Added %i achievements for %@ for game %@", unlockedCount,
          gamertag, responseData[@"Game"][@"Name"]);
    
}

-(void)processImage:(NSString *)savedImagePath
{
    // TODO
    NSLog(@"Downloaded image: %@", savedImagePath);
    
}

-(void)sendRequestWithURL:(NSString *)url retries:(int)retries success:(void(^)(NSDictionary *responseDictionary))success
{
    NSString *url_encoded = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *requestKey = url_encoded;
    [self.pendingRequests addObject:requestKey];

    NSString *errorMessage = nil;
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *savedDataPath = [NSString stringWithFormat:@"%@/XboxLiveClient-%@.json", docsDir, [self urlToFilename:requestKey]];
    if (self.isOfflineMode) {
        // If we are running in Offline Mode, check if we have saved response for this request.
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:savedDataPath];
        if (!fileExists) {
            errorMessage = [NSString stringWithFormat:@"OfflineMode enabled, but no saved JSON data found: %@", savedDataPath];
        } else {
            NSError *jsonError;
            NSData *jsonData = [NSData dataWithContentsOfFile:savedDataPath options:kNilOptions error:&jsonError];
            if (jsonError) {
                errorMessage = [NSString stringWithFormat:@"Failed to read JSON data from file %@: %@", savedDataPath, jsonError];
            } else {
                id result = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
                if (jsonError || ![result isKindOfClass:[NSDictionary class]]) {
                    errorMessage = [NSString stringWithFormat:@"Failed to serialize JSON data from file %@: %@", savedDataPath, jsonError];
                } else {
                    // Call success block before checkPendingReqeusts, in case it adds requests to the queue.
                    success((NSDictionary *)result);
                    [self.pendingRequests removeObject:requestKey];
                    [self checkPendingRequests];
                }
            }
        }
        if (errorMessage && !self.isInitializationError) {
            self.isInitializationError = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionBlock(errorMessage);
            });
        }
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url_encoded]];
    NSLog(@"Sending request: %@", url_encoded);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *urlResponse, NSData *responseData, NSError *connectionError)
     {
         NSString *myErrorMessage = nil;
         NSDictionary *myResponseDictionary = nil;
         if (connectionError) {
             myErrorMessage = [NSString stringWithFormat:@"ERROR connecting to %@", url_encoded];
         } else {
             
             NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
             if (!response) {
                 myErrorMessage = [NSString stringWithFormat:@"Empty response from %@", url_encoded];
             } else {
                 BOOL isSuccess = [response[@"Success"] boolValue];
                 if (!isSuccess) {
                     myErrorMessage = response[@"Error"];
                 } else {
                     myResponseDictionary = response;
                 }
             }
         }
         if (myErrorMessage) {
             if (retries > 0) {
                 NSLog(@"Retring request for %@", url_encoded);
                 [self sendRequestWithURL:url retries:(retries-1) success:success];
             } else {
                 if (!self.isInitializationError) {
                     self.isInitializationError = YES;
                     NSLog(@"Request failed at %@: %@", url_encoded, myErrorMessage);
                     dispatch_async(dispatch_get_main_queue(), ^{
                         self.completionBlock(myErrorMessage);
                     });
                 }
             }
         } else {
             
             // Call success block before checkPendingReqeusts, in case it adds requests to the queue.
             success(myResponseDictionary);
             [self.pendingRequests removeObject:requestKey];
             [self checkPendingRequests];
             
             // Save to file, for use in Offline Mode.
             NSLog(@"Saving response to file: %@", savedDataPath);
             [responseData writeToFile:savedDataPath atomically:YES];
         }
     }];
    
}

-(void)imageRequestWithURL:(NSString *)url retries:(int)retries success:(void(^)(NSString *savedImagePath))success
{
    NSString *url_encoded = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *requestKey = url_encoded;
    
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *savedDataPath = [NSString stringWithFormat:@"%@/XboxLiveClient-%@", docsDir, [self urlToFilename:requestKey]];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:savedDataPath];
    if (fileExists) {
        // We might have already downloaded this image, e.g. if multiple friends played the same game.
        success(savedDataPath);
        return;
    } else {
        if (self.isOfflineMode) {
            if (!self.isInitializationError) {
                self.isInitializationError = YES;
                NSString *errorMessage = [NSString stringWithFormat:@"OfflineMode enabled, but no saved image found: %@", savedDataPath];
                NSLog(@"%@", errorMessage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.completionBlock(errorMessage);
                });
            }
            return;
        }
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url_encoded]];
    NSLog(@"Sending image request: %@", url_encoded);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *urlResponse, NSData *responseData, NSError *connectionError)
     {
         NSString *myErrorMessage = nil;
         if (connectionError) {
             myErrorMessage = [NSString stringWithFormat:@"ERROR connecting to %@", url_encoded];
         } else {
             if (!responseData) {
                 myErrorMessage = [NSString stringWithFormat:@"Empty response from %@", url_encoded];
             }
         }
         if (myErrorMessage) {
             if (retries > 0) {
                 NSLog(@"Retrying image request for %@", url_encoded);
                 [self imageRequestWithURL:url retries:(retries-1) success:success];
             } else {
                 if (!self.isInitializationError) {
                     self.isInitializationError = YES;
                     NSLog(@"Request for image failed %@: %@", url_encoded, myErrorMessage);
                     dispatch_async(dispatch_get_main_queue(), ^{
                         self.completionBlock(myErrorMessage);
                     });
                 }
             }
         } else {
             
             // Save image data to file, return path to caller.
             NSLog(@"Saving image to file: %@", savedDataPath);
             [responseData writeToFile:savedDataPath atomically:YES];
             
             success(savedDataPath);
         }
     }];
}

-(NSString *)urlToFilename:(NSString *)url
{

    NSString *new = url;
    // Images are downloaded directly from xboxlive servers.
    new = [new stringByReplacingOccurrencesOfString:@"https://avatar-ssl.xboxlive.com/" withString:@""];
    
    // JSON data is obtained from xboxapi.
    new = [new stringByReplacingOccurrencesOfString:@"http://xboxapi.com/" withString:@""];
    new = [new stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    new = [new stringByReplacingOccurrencesOfString:@"%20" withString:@"_"];
    return new;
}

# pragma mark - interface methods


-(NSArray *) achievements
{
    return [Achievement achievementsWithArray:self.achievementsFromJSON];
}

-(NSArray *) achievementsWithGamertag:(NSString *)gamertag
{
    NSMutableArray *filtered = [[NSMutableArray alloc] init];
    for (NSDictionary *achievementDict in self.achievementsFromJSON) {
        if ([achievementDict[@"Player"][@"Gamertag"] isEqualToString:gamertag]) {
            [filtered addObject:achievementDict];
        }
    }
    return [Achievement achievementsWithArray:filtered];
}

-(Profile *) userProfile
{
    return [[Profile alloc] initWithDictionary:self.userProfileFromJSON];
}

-(NSArray *) friendProfiles
{
    return [Profile profilesWithArray:self.friendProfilesFromJSON];
}

-(Profile *) friendProfileWithGamertag:(NSString *)gamertag
{
    for (NSDictionary *friendProfile in self.friendProfilesFromJSON) {
        if ([friendProfile[@"Player"][@"Gamertag"] isEqualToString:gamertag]) {
            return [[Profile alloc] initWithDictionary:friendProfile];
        }
    }
    return nil;
}

// TODO: Move to util file
+(UIImage *)createRoundedUserWithImage:(UIImage *)image {
    CGSize imageSize = image.size;
    CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);

    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);

    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:imageRect];
    [path addClip];
    [image drawInRect:imageRect];

    // Uncomment for image outline
    /*
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [[UIColor grayColor] CGColor]);
    [path setLineWidth:2.0f];
    [path stroke];
    */

    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return roundedImage;
}

@end









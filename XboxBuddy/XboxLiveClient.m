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
@property int defaultRetries;

// Callback to the object that envoked our init method.
@property (nonatomic, copy) void (^completionBlock)(NSString *errorDescription);

// Only methods that sends requests to the remote Xbox Live API.
-(void)sendRequestWithURL:(NSString *)url success:(void(^)(NSDictionary *responseDictionary))success;
-(void)imageRequestWithURL:(NSString *)url success:(void(^)(NSString *savedImagePath))success;

// Recursive versions of above.
-(void)sendRequestWithURL:(NSString *)url success:(void(^)(NSDictionary *responseDictionary))success withRetries:(int)retries;
-(void)imageRequestWithURL:(NSString *)url success:(void(^)(NSString *savedImagePath))success withRetries:(int)retries;

// Methods that determine when initialization is complete.
-(void)checkSavedDataExists;
-(void)checkPendingRequests;
-(void)requestsDidComplete;

// Called from our async request completion block to handle received data.
-(void)processProfile:(NSDictionary *)responseData;
-(void)processFriends:(NSDictionary *)responseData;
-(void)processImage:(NSString *)savedImagePath;

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

+(NSString *)filePathForImageUrl:(NSString *)url
{
    NSString *filename = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *extension = @"jpg";
    NSArray *image_extensions = @[@"jpeg", @"jpg", @"png",
                                  @"JPEG", @"JPG", @"PNG"];
    if ([image_extensions containsObject:[url substringFromIndex:[url length]-4]] ||
        [image_extensions containsObject:[url substringFromIndex:[url length]-3]]) {
        // Url already ends in image suffix, no need to append jpg.
        extension = nil;
    }
    if (extension) {
        filename = [NSString stringWithFormat:@"%@.%@", filename, extension];
    }
    
    // Images are downloaded directly from xboxlive servers.
    filename = [filename stringByReplacingOccurrencesOfString:@"https://image-ssl.xboxlive.com/" withString:@""];
    filename = [filename stringByReplacingOccurrencesOfString:@"http://avatar.xboxlive.com/" withString:@""];
    filename = [filename stringByReplacingOccurrencesOfString:@"http://download.xbox.com/" withString:@""];
    filename = [filename stringByReplacingOccurrencesOfString:@"https://live.xbox.com/" withString:@""];
    
    // Replace unwanted symbols.
    filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    filename = [filename stringByReplacingOccurrencesOfString:@"%20" withString:@"_"];
    
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [NSString stringWithFormat:@"%@/XboxLiveClient-%@", docsDir, filename];
    return filePath;
}

-(NSString *)filePathForUrl:(NSString *)url withExtension:(NSString *)extension
{
    NSString *filename = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (extension) {
        filename = [NSString stringWithFormat:@"%@.%@", filename, extension];
    }
    
    // JSON data is obtained from xboxapi.
    filename = [filename stringByReplacingOccurrencesOfString:@"http://xboxleaders.com/" withString:@""];
    
    // Replace unwanted symbols.
    filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    filename = [filename stringByReplacingOccurrencesOfString:@"%20" withString:@"_"];
    
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [NSString stringWithFormat:@"%@/XboxLiveClient-%@", docsDir, filename];
    return filePath;
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
    self.defaultRetries = 3;
    
    if (self.isOfflineMode) {
        [self checkSavedDataExists];
    }
    
    NSLog(@"XboxLiveClient initializing %@with gamertag %@",
          (self.isOfflineMode) ? @"in OFFLINE MODE " : @"", userGamertag);
    self.startInit = [NSDate date];
    
    // Send Friends request.
    NSString *friends_url_str = [NSString stringWithFormat: @"http://xboxleaders.com/api/friends.json?gamertag=%@", self.userGamertag];
    [self sendRequestWithURL:friends_url_str success:
        ^(NSDictionary *responseData) { [self processFriends:responseData]; }];
    
}

-(void)checkSavedDataExists
{
    // Check saved data for user friend list only, assume if we have that we have the rest.
    NSString *friends_url_str = [NSString stringWithFormat: @"http://xboxleaders.com/api/friends.json?gamertag=%@", self.userGamertag];
    NSString *savedDataPath = [self filePathForUrl:friends_url_str withExtension:@"json"];
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
               NSNumber *first_date = ((NSDictionary*)a)[@"achievement"][@"unlockdate"];
               NSNumber *second_date = ((NSDictionary*)b)[@"achievement"][@"unlockdate"];
               return [second_date compare:first_date];     // Descending.
         }];
        
    // Create list of friend gamertags, sorted by last achievement earned.
    NSMutableDictionary *lastAchievement = [[NSMutableDictionary alloc] init];
    NSMutableArray *gamertagArray = [[NSMutableArray alloc] init];
    for (NSDictionary *achievement in self.achievementsFromJSON) {
        NSString *gamertag = achievement[@"player"][@"gamertag"];
        if (![gamertagArray containsObject:gamertag]) {
            [gamertagArray addObject:gamertag];
            // This is the most recent achievement earned by this player, remember it.
            NSMutableDictionary *achievement_mdict = [[NSMutableDictionary alloc] initWithDictionary:achievement];
            lastAchievement[gamertag] = achievement_mdict;
        }
    }
    
    // Add the last achievement earned to user profile and each friend profile.
    NSMutableDictionary *user_profile_mdict = [[NSMutableDictionary alloc] initWithDictionary:self.userProfileFromJSON];
    NSMutableDictionary *user_last_achievement = lastAchievement[self.userGamertag];
    if (user_last_achievement) {
        user_profile_mdict[@"achievement"] = user_last_achievement;
    } else {
        // Last achivement for current user could be null if they haven't earned one yet; unlikely but possible.
        user_profile_mdict[@"achievement"] = [NSNull null];
    }
    self.userProfileFromJSON = user_profile_mdict;
    for (int i=0; i < [self.friendProfilesUnsorted count]; i++) {
        NSDictionary *profile_dict = self.friendProfilesUnsorted[i];
        NSMutableDictionary *profile_mdict = [[NSMutableDictionary alloc] initWithDictionary:profile_dict];
        NSMutableDictionary *profile_acheivement = lastAchievement[profile_mdict[@"gamertag"]];
        if (profile_acheivement) {
            profile_mdict[@"achievement"] = profile_acheivement;
        } else {
            // Last achivement will be null if friend has their recent activity hidden.
            profile_mdict[@"achievement"] = [NSNull null];
        }
        self.friendProfilesUnsorted[i] = profile_mdict;
    }
    
    // Sort friends by last achievement earned.
    self.friendProfilesFromJSON = [self.friendProfilesUnsorted sortedArrayUsingComparator:
           ^NSComparisonResult(id a, id b) {
               NSString *first_gamertag = ((NSDictionary *)a)[@"gamertag"];
               NSString *second_gamertag = ((NSDictionary *)b)[@"gamertag"];
               
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
    int count = (int)[responseData[@"friends"] count];
    NSLog(@"Found %i Friends for current user", count);
    
    if (self.isInitializationError) {
        NSLog(@"Initialization error detected, skipping fetching friend profile.");
        return;
    }
    
    // Get profiles for all my friends.
    for (NSDictionary *friend in responseData[@"friends"]) {
        NSString *friendGamertag = friend[@"gamertag"];
        NSString *profile_url_str = [NSString stringWithFormat:
                                     @"http://xboxleaders.com/api/profile.json?gamertag=%@",
                                     friendGamertag];
        [self sendRequestWithURL:profile_url_str success:
            ^(NSDictionary *responseData) { [self processProfile:responseData]; }];
    }
    
    // Get profile for current user.
    NSString *profile_url_str = [NSString stringWithFormat: @"http://xboxleaders.com/api/profile.json?gamertag=%@", self.userGamertag];
    [self sendRequestWithURL:profile_url_str success:
        ^(NSDictionary *responseData) { [self processProfile:responseData]; }];
    
}

-(void)processProfile:(NSDictionary *)responseData
{
    NSString *friendGamertag = responseData[@"gamertag"];
    if ([friendGamertag isEqualToString:self.userGamertag]) {
        self.userProfileFromJSON = responseData;
        NSLog(@"Added profile for current user %@", self.userGamertag);
    } else {
        [self.friendProfilesUnsorted addObject:responseData];
        unsigned long count = 0;
        if (responseData[@"recentactivity"] != [NSNull null]) {
            count = (unsigned long)[responseData[@"recentactivity"] count];
        }
        NSLog(@"Added profile for friend %@ with %lu recent games", friendGamertag, count);
    }
    
    // Download gamerpic and avatar images.
    NSString *gamerpic_url_str = responseData[@"avatar"][@"large"];
    [self imageRequestWithURL:gamerpic_url_str success:
        ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
    NSString *avatar_url_str = responseData[@"avatar"][@"full"];
    [self imageRequestWithURL:avatar_url_str success:
        ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
    
    if (self.isInitializationError) {
        NSLog(@"Initialization error detected, skipping fetching achievements.");
        return;
    }
    
    // Save a summary of the player info with the achievement.
    NSDictionary *player_dict = @{@"gamertag": responseData[@"gamertag"],
                                  @"gamerscore": responseData[@"gamerscore"],
                                  @"avatar": responseData[@"avatar"]};
    
    // Get Acheivements for the Recent Games.
    if (responseData[@"recentactivity"] != [NSNull null]) {
        NSArray *games = responseData[@"recentactivity"];
        for (NSDictionary *game in games) {
            
            // Some of these "games" are console apps like Netflix that don't have achievements.
            // Detect them by analyzing the URL since this API doesn't provide isApp flag.
            NSString *game_boxart_url_str = game[@"artwork"][@"large"];
            BOOL isApp = [game[@"isapp"] boolValue];
            if (isApp) {
                NSLog(@"Skipping recent game console app for %@: %@", friendGamertag, game[@"title"]);
                continue;   // Console app, skip it.
            }
            
            // Get game artwork.
            [self imageRequestWithURL:game_boxart_url_str success:
                ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
            
            // Get game achievements.
            NSString *acheivements_url_str = [NSString stringWithFormat:
                                              @"http://xboxleaders.com/api/achievements.json?gameid=%@&gamertag=%@",
                                              game[@"id"], friendGamertag];
            
            [self sendRequestWithURL:acheivements_url_str success:
             ^(NSDictionary *responseData) { [self processAchievements:responseData forPlayer:player_dict forGame:game]; }];
        }
    } else {
        // User has game history hidden in their privacy settings.
        NSLog(@"Cannot view Games for %@: Privacy Settings Enabled", friendGamertag);
    }
    
}

-(void)processAchievements:(NSDictionary *)responseData forPlayer:(NSDictionary *)player forGame:(NSDictionary *)game
{
    NSString *gamertag = responseData[@"gamertag"];
    int unlockedCount = 0;
    if (responseData[@"achievements"] != [NSNull null]) {
    
        //NSArray *achievements = responseData[@"Achievements"];
        NSMutableArray *achievements = [[NSMutableArray alloc] initWithArray: responseData[@"achievements"]];
        for (NSDictionary *achievement in achievements) {
    
            BOOL isUnlocked = [achievement[@"unlocked"] boolValue];
            if (isUnlocked) {
                // Get achievement images.
                NSString *achievement_image_unlocked_url_str = achievement[@"artwork"][@"unlocked"];
                NSString *achievement_image_locked_url_str = achievement[@"artwork"][@"locked"];
                
                [self imageRequestWithURL:achievement_image_unlocked_url_str success:
                    ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
                [self imageRequestWithURL:achievement_image_locked_url_str success:
                    ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
                
                // Save the Game and Player info with the Achievement.
                [self.achievementsUnsorted addObject: @{@"player": player,
                                                        @"game": game,
                                                        @"achievement": achievement}];
                
                unlockedCount++;
            }
        }
    }
    NSLog(@"Added %i achievements for %@ for game %@", unlockedCount,
          gamertag, responseData[@"game"]);
}

-(void)processImage:(NSString *)savedImagePath
{
    // Placeholder, do nothing for now.
    
}

-(void)sendRequestWithURL:(NSString *)url success:(void(^)(NSDictionary *responseDictionary))success
{
    // Need to pass retries as argument to function to handle recursive case when we retry and recall it.
    [self sendRequestWithURL:url success:success withRetries:self.defaultRetries];
}

-(void)sendRequestWithURL:(NSString *)url success:(void(^)(NSDictionary *responseDictionary))success withRetries:(int)retries
{
    NSString *url_encoded = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *requestKey = url_encoded;
    [self.pendingRequests addObject:requestKey];

    NSString *errorMessage = nil;
    NSString *savedDataPath = [self filePathForUrl:url withExtension:@"json"];
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
                    success((NSDictionary *)result[@"data"]);
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
    (retries == self.defaultRetries) ? NSLog(@"Sending request: %@", url_encoded): NSLog(@"Retrying request: %@", url_encoded);
    
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
                 BOOL isSuccess = [response[@"status"] isEqualToString:@"success"];
                 if (!isSuccess) {
                     myErrorMessage = response[@"data"][@"message"];
                 } else {
                     // Special Case.
                     if ([url rangeOfString:@"profile"].location != NSNotFound &&
                         response[@"data"][@"recentactivity"] == [NSNull null] &&
                         retries > 0) {     // Don't fail permanently for this reason, just retry.
                         
                         // Sometimes the API incorrectly returns "null" for recent activity, so retry to be sure.
                         // If this friend really does have privacy settings enabled then we'll retry for nothing.
                         myErrorMessage = @"Recent Activity missing for this user.";
                     } else {
                         // Success.
                         myResponseDictionary = response[@"data"];
                     }
                 }
             }
         }
         if (myErrorMessage) {
             if (retries > 0) {
                 [self sendRequestWithURL:url success:success withRetries:(retries-1)];
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
             // TODO: Add DEBUG logging, for now just comment out.
             //NSLog(@"Saving response to file: %@", savedDataPath);    // DEBUG
             [responseData writeToFile:savedDataPath atomically:YES];
         }
     }];
    
}

-(void)imageRequestWithURL:(NSString *)url success:(void(^)(NSString *savedImagePath))success
{
    // Need to pass retries as argument to function to handle recursive case when we retry and recall it.
    [self imageRequestWithURL:url success:success withRetries:self.defaultRetries];
}

-(void)imageRequestWithURL:(NSString *)url success:(void(^)(NSString *savedImagePath))success withRetries:(int)retries
{
    NSString *savedDataPath = [XboxLiveClient filePathForImageUrl:url];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:savedDataPath];
    if (fileExists) {
        // We might have already downloaded this image, e.g. if multiple friends played the same game.
        //NSLog(@"Using previously downloaded image for %@ found at %@", url, savedDataPath);   // DEBUG
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

    NSString *url_encoded = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url_encoded]];
    //NSLog(@"Sending image request: %@", url_encoded); // DEBUG
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
                 //NSLog(@"Retrying image request for %@", url_encoded);    // DEBUG
                 [self imageRequestWithURL:url success:success withRetries:(retries-1)];
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
             //NSLog(@"Saving image to file: %@", savedDataPath);   // DEBUG
             [responseData writeToFile:savedDataPath atomically:YES];
             success(savedDataPath);
         }
     }];
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
        if ([achievementDict[@"player"][@"gamertag"] isEqualToString:gamertag]) {
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
        if ([friendProfile[@"gamertag"] isEqualToString:gamertag]) {
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









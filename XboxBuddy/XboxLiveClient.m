//
//  XboxLiveAPI.m
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "XboxLiveClient.h"
#import "Achievement.h"

NSString * const XboxLiveClientDidInitNotification = @"XboxLiveClientDidInitNotification";

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
@property NSMutableDictionary *recentGamesWithGamertag;
@property NSDate *startInit;
@property NSDate *endInit;
@property NSTimeInterval secondsToInit;

// Configuration settings
@property int defaultRetries;
@property int defaultCachePolicy;
@property int maxRecentGames;

// Only methods that sends requests to the remote Xbox Live API.
-(void)sendRequestWithURL:(NSString *)url success:(void(^)(NSDictionary *responseDictionary))success;
-(void)imageRequestWithURL:(NSString *)url success:(void(^)(NSString *savedImagePath))success;

// Recursive versions of above.
-(void)sendRequestWithURL:(NSString *)url success:(void(^)(NSDictionary *responseDictionary))success withRetries:(int)retries
          withCachePolicy:(NSURLRequestCachePolicy)cachePolicy;
-(void)imageRequestWithURL:(NSString *)url success:(void(^)(NSString *savedImagePath))success withRetries:(int)retries;

// Methods that determine when initialization is complete.
-(void)checkSavedDataExists;
-(void)checkPendingRequests;
-(void)requestsDidComplete;

// Called from our async request completion block to handle received data.
-(void)processProfiles:(NSDictionary *)responseData;
-(void)processGames:(NSDictionary *)responseData;
-(void)processAchievements:(NSDictionary *)responseData;
-(void)processImage:(NSString *)savedImagePath;

@end

@implementation XboxLiveClient

static XboxLiveClient *Instance;
static BOOL IsOfflineMode;
static BOOL IsDemoMode;

+(XboxLiveClient *)instance
{
    @synchronized(self) {
        if (!Instance) {
            Instance = [[XboxLiveClient alloc] init];
        }
    }
    return Instance;
}

+(void)resetInstance
{
    @synchronized(self) {
        // Destroy old instance by overwriting with an uninitialized one.
        NSLog(@"Destroyed instance of XboxLiveClient initialized for %@.", Instance.userGamertag);
        Instance = [[XboxLiveClient alloc] init];
    }
}

+(BOOL)isOfflineMode { return IsOfflineMode; }
+(void)setIsOfflineMode:(BOOL)isOfflineMode { IsOfflineMode = isOfflineMode; }

+(BOOL)isDemoMode { return IsDemoMode; }
+(void)setIsDemoMode:(BOOL)isDemoMode { IsDemoMode = isDemoMode; }

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
    filename = [filename stringByReplacingOccurrencesOfString:@"https://avatar-ssl.xboxlive.com/" withString:@""];
    filename = [filename stringByReplacingOccurrencesOfString:@"http://catalog.xboxapi.com/" withString:@""];
    filename = [filename stringByReplacingOccurrencesOfString:@"https://live.xbox.com/" withString:@""];
    filename = [filename stringByReplacingOccurrencesOfString:@"http://image.xboxlive.com/" withString:@""];
    
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
    filename = [filename stringByReplacingOccurrencesOfString:@"http://xboxapi.com/" withString:@""];
    
    // Replace unwanted symbols.
    filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    filename = [filename stringByReplacingOccurrencesOfString:@"%20" withString:@"_"];
    
    NSString *docsDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [NSString stringWithFormat:@"%@/XboxLiveClient-%@", docsDir, filename];
    return filePath;
}

-(void)initInstance
{
    if (![User currentUser]) {
        [self initializationDidFail:@"No currentUser."];
        return;
    }
    
    self.userGamertag = [User currentUser].gamertag;
    self.pendingRequests = [[NSMutableArray alloc] init];
    self.achievementsUnsorted = [[NSMutableArray alloc] init];
    self.friendProfilesUnsorted = [[NSMutableArray alloc] init];
    self.recentGamesWithGamertag = [[NSMutableDictionary alloc] init];
    self.isInitializationError = NO;
    self.defaultRetries = 3;
    self.defaultCachePolicy = NSURLRequestUseProtocolCachePolicy;
    self.maxRecentGames = 3;
    
    if (IsOfflineMode) {
        [self checkSavedDataExists];
    }
    
    NSLog(@"XboxLiveClient initializing %@with gamertag %@",
          (IsOfflineMode) ? @"in OFFLINE MODE " : @"", self.userGamertag);
    self.startInit = [NSDate date];
    
    // Send Friends request.
    NSString *friends_url_str = [NSString stringWithFormat: @"http://xboxapi.com/v1/friends/%@", self.userGamertag];
    [self sendRequestWithURL:friends_url_str success:
        ^(NSDictionary *responseData) { [self processFriends:responseData]; }];
    
}

-(void)checkSavedDataExists
{
    // Check saved data for user friend list only, assume if we have that we have the rest.
    NSString *friends_url_str = [NSString stringWithFormat: @"http://xboxapi.com/v1/friends/%@", self.userGamertag];
    NSString *savedDataPath = [self filePathForUrl:friends_url_str withExtension:@"json"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:savedDataPath];
    if (!fileExists) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"No Saved Data Found"
                              message:@"Overriding Offline Mode for this run."
                              delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        NSLog(@"No Saved Data found at %@", savedDataPath);
        NSLog(@"Overriding OFFLINE MODE for this run.");
        IsOfflineMode = NO;
        [alert show];
    } else {
        NSLog(@"Saved Data found at %@", savedDataPath);
    }
}


-(void)checkPendingRequests
{
    @synchronized(self) {
        
        if (self.isInitializationError) {
            // Error already returned to caller.
            return;
        }
    
        if ([self.pendingRequests count] == 0) {
            [self requestsDidComplete];
        }
    }
}

-(void)requestsDidComplete
{
    if (IsDemoMode) {
        [self prepDataForDemo];
    }
    
    // Sort achievements by date earned.
    self.achievementsFromJSON = [self.achievementsUnsorted sortedArrayUsingComparator:
         ^NSComparisonResult(id a, id b) {
               NSNumber *first_date = ((NSDictionary*)a)[@"Achievement"][@"EarnedOn-UNIX"];
               NSNumber *second_date = ((NSDictionary*)b)[@"Achievement"][@"EarnedOn-UNIX"];
               return [second_date compare:first_date];     // Descending.
         }];
        
    // Create list of friend gamertags, sorted by last achievement earned.
    NSMutableDictionary *lastAchievement = [[NSMutableDictionary alloc] init];
    NSMutableArray *gamertagArray = [[NSMutableArray alloc] init];
    for (NSDictionary *achievement in self.achievementsFromJSON) {
        NSString *gamertag = achievement[@"Player"][@"Gamertag"];
        if (![gamertagArray containsObject:gamertag]) {
            [gamertagArray addObject:gamertag];
            // This is the most recent achievement earned by this player, remember it.
            NSMutableDictionary *achievement_mdict = [[NSMutableDictionary alloc] initWithDictionary:achievement];
            lastAchievement[gamertag] = achievement_mdict;
        }
    }
    
    // Add the last game played to user profile and each friend profile.
    NSMutableDictionary *user_profile_mdict = [[NSMutableDictionary alloc] initWithDictionary:self.userProfileFromJSON];
    NSMutableArray *user_recent_games = self.recentGamesWithGamertag[self.userGamertag];
    if (user_recent_games) {
        user_profile_mdict[@"RecentGames"] = user_recent_games;
    } else {
        // Recent games for current user could be null if they have their recent activity hidden.
        user_profile_mdict[@"RecentGames"] = [NSNull null];
    }
    self.userProfileFromJSON = user_profile_mdict;
    for (int i=0; i < [self.friendProfilesUnsorted count]; i++) {
        NSDictionary *profile_dict = self.friendProfilesUnsorted[i];
        NSMutableDictionary *profile_mdict = [[NSMutableDictionary alloc] initWithDictionary:profile_dict];
        NSMutableArray *profile_recent_games = self.recentGamesWithGamertag[profile_dict[@"Player"][@"Gamertag"]];
        if (profile_recent_games) {
            profile_mdict[@"RecentGames"] = profile_recent_games;
        } else {
            // Last achivement will be null if friend has their recent activity hidden.
            profile_mdict[@"RecentGames"] = [NSNull null];
        }
        self.friendProfilesUnsorted[i] = profile_mdict;
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
          (IsOfflineMode) ? @"in OFFLINE MODE " : @"", self.userGamertag, count, self.secondsToInit);
    
    // Done, post notification.
    [[NSNotificationCenter defaultCenter] postNotificationName:XboxLiveClientDidInitNotification object:nil];
    
}

-(void)initializationDidFail:(NSString *)errorMessage
{
    self.isInitializationError = YES;
    NSLog(@"Failed to initialize xboxLiveClient: %@", errorMessage);
    
    // TODO: No one is listening for this right now.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"InitialDataLoadFailed" object:nil userInfo:nil];
}

-(void)processFriends:(NSDictionary *)responseData
{
    int count = (int)[responseData[@"Friends"] count];
    NSLog(@"Found %i Friends for current user", count);
    
    if (self.isInitializationError) {
        NSLog(@"Initialization error detected, skipping fetching friend profile.");
        return;
    }
    
    NSMutableArray *friendGamertags = [[NSMutableArray alloc] init];
    for (NSDictionary *friend in responseData[@"Friends"]) {
        [friendGamertags addObject:friend[@"GamerTag"]];
    }
    if (IsDemoMode) {
        friendGamertags = [self prepFriendsListForDemo:friendGamertags];
    }
    
    // Get profiles for all my friends.
    for (NSString *friendGamertag in friendGamertags) {
        NSString *profile_url_str = [NSString stringWithFormat:
                                     @"http://xboxapi.com/v1/profile/%@",
                                     friendGamertag];
        [self sendRequestWithURL:profile_url_str success:
            ^(NSDictionary *responseData) { [self processProfiles:responseData]; }];
    }
    
    // Get profile for current user.
    NSString *profile_url_str = [NSString stringWithFormat: @"http://xboxapi.com/v1/profile/%@", self.userGamertag];
    [self sendRequestWithURL:profile_url_str success:
        ^(NSDictionary *responseData) { [self processProfiles:responseData]; }];
    
    // Get Games for all my friends.
    for (NSString *friendGamertag in friendGamertags) {
        NSString *games_url_str = [NSString stringWithFormat:
                                     @"http://xboxapi.com/v1/games/%@",
                                     friendGamertag];
        [self sendRequestWithURL:games_url_str success:
         ^(NSDictionary *responseData) { [self processGames:responseData]; }];
        
    }
    
    // Get games for current user.
    NSString *games_url_str = [NSString stringWithFormat: @"http://xboxapi.com/v1/games/%@", self.userGamertag];
    [self sendRequestWithURL:games_url_str success:
     ^(NSDictionary *responseData) { [self processGames:responseData]; }];
    
}

-(void)processProfiles:(NSDictionary *)responseData
{
    NSString *friendGamertag = responseData[@"Player"][@"Gamertag"];
    if ([friendGamertag isEqualToString:self.userGamertag]) {
        self.userProfileFromJSON = responseData;
        NSLog(@"Added profile for current user %@", self.userGamertag);
    } else {
        [self.friendProfilesUnsorted addObject:responseData];
        NSLog(@"Added profile for friend %@", friendGamertag);
    }
    
    
}

-(void)processGames:(NSDictionary *)responseData
{
    // Download gamerpic and avatar images.
    NSString *gamerpic_url_str = responseData[@"Player"][@"Avatar"][@"Gamerpic"][@"Large"];
    [self imageRequestWithURL:gamerpic_url_str success:
     ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
    NSString *avatar_url_str = responseData[@"Player"][@"Avatar"][@"Body"];
    [self imageRequestWithURL:avatar_url_str success:
     ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
    
    if (self.isInitializationError) {
        NSLog(@"Initialization error detected, skipping fetching achievements.");
        return;
    }
    
    // Get Acheivements for a handful of the most recently played games.
    NSString *friendGamertag = responseData[@"Player"][@"Gamertag"];
    int recent_game_count = 0;
    if ([responseData[@"Games"] isKindOfClass:[NSArray class]]) {
        NSArray *games = responseData[@"Games"];
        
        if (IsDemoMode) {
            games = [self prepGamesListForDemo:games withGamertag:friendGamertag];
        }
        
        for (NSDictionary *game in games) {
            
            // Some of these "games" are console apps like Netflix that don't have achievements.
            // Detect them by analyzing the URL since this API doesn't provide isApp flag.
            NSString *game_boxart_url_str = game[@"BoxArt"][@"Large"];
            if ([game_boxart_url_str rangeOfString:@"/consoleAssets/"].location != NSNotFound) {
                //NSLog(@"Skipping recent game console app for %@: %@", friendGamertag, game[@"Name"]);   // DEBUG
                continue;   // Console app, skip it.
            }
            
            // Save the recent games (even if they have no achievements).
            if (!self.recentGamesWithGamertag[friendGamertag]) {
                self.recentGamesWithGamertag[friendGamertag] = [[NSMutableArray alloc] init];
            }
            [self.recentGamesWithGamertag[friendGamertag] addObject:game];
            
            // No need to fetch achievements if none unlocked.
            if ([game[@"Progress"][@"Achievements"] intValue] == 0) {
                //NSLog(@"Skipping game with no achievements unlocked for %@: %@", friendGamertag, game[@"Name"]);   // DEBUG
                continue;
            }
            
            
            // Get game artwork.
            [self imageRequestWithURL:game_boxart_url_str success:
             ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
            
            // Get game achievements.
            NSString *acheivements_url_str = [NSString stringWithFormat:
                                              @"http://xboxapi.com/v1/achievements/%@/%@",
                                              game[@"ID"], friendGamertag];
            
            [self sendRequestWithURL:acheivements_url_str success:
             ^(NSDictionary *responseData) { [self processAchievements:responseData]; }];
            
            // Exit loop when we've collected the desired number of most recent games.
            recent_game_count++;
            if (recent_game_count == self.maxRecentGames) {
                break;
            }
        }
    } else {
        // User has game history hidden in their privacy settings.
        NSLog(@"Cannot view Games for %@: Privacy Settings Enabled", friendGamertag);
    }
    
    if ([friendGamertag isEqualToString:self.userGamertag]) {
        NSLog(@"Added %i recent games for current user %@", recent_game_count, self.userGamertag);
    } else {
        NSLog(@"Added %i recent games for friend %@", recent_game_count, friendGamertag);
    }
    
}

-(void)processAchievements:(NSDictionary *)responseData
{
    int unlockedCount = 0;
    NSString *gamertag = responseData[@"Player"][@"Gamertag"];
    NSDictionary *gameDict = responseData[@"Game"];
    
    if (responseData[@"Achievements"] != [NSNull null]) {
    
        NSMutableArray *achievements = [[NSMutableArray alloc] initWithArray: responseData[@"Achievements"]];
        
        if (IsDemoMode) {
            achievements = [self prepAchievementsForDemo:achievements withGamertag:gamertag withGame:gameDict];
        }
        
        for (NSDictionary *achievement in achievements) {
    
            long earnedOn = [achievement[@"EarnedOn-UNIX"] boolValue];
            if (earnedOn != 0) {
                
                // Save the Game and Player info with the Achievement.
                [self.achievementsUnsorted addObject: @{@"Player": responseData[@"Player"],
                                                        @"Game": responseData[@"Game"],
                                                        @"Achievement": achievement}];
                
                // Get achievement image.
                NSString *achievement_image_url_str = achievement[@"UnlockedTileUrl"];
                if (![achievement_image_url_str isKindOfClass:[NSString class]]) {
                    achievement_image_url_str = achievement[@"TileUrl"];
                }
                [self imageRequestWithURL:achievement_image_url_str success:
                    ^(NSString *savedImagePath) { [self processImage:savedImagePath]; }];
                
                unlockedCount++;
            }
        }
    }
    NSLog(@"Added %i achievements for %@ for game %@", unlockedCount, gamertag, gameDict[@"Name"]);
}

-(void)processImage:(NSString *)savedImagePath
{
    // Placeholder, do nothing for now.
    
}

-(void)sendRequestWithURL:(NSString *)url success:(void(^)(NSDictionary *responseDictionary))success
{
    // Need to pass retries as argument to function to handle recursive case when we retry and recall it.
    [self sendRequestWithURL:url success:success withRetries:self.defaultRetries withCachePolicy:self.defaultCachePolicy];
}

-(void)sendRequestWithURL:(NSString *)url success:(void(^)(NSDictionary *responseDictionary))success
              withRetries:(int)retries withCachePolicy:(NSURLRequestCachePolicy)cachePolicy
{
    NSString *url_encoded = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *requestKey = url_encoded;
    [self.pendingRequests addObject:requestKey];

    NSString *errorMessage = nil;
    NSString *savedDataPath = [self filePathForUrl:url withExtension:@"json"];
    if (IsOfflineMode) {
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
            [self initializationDidFail:errorMessage];
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
                 // Force server to reload data on retries.
                 [self sendRequestWithURL:url success:success withRetries:(retries-1)
                      withCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
             } else {
                 if (!self.isInitializationError) {
                     NSLog(@"Request failed at %@: %@", url_encoded, myErrorMessage);
                     [self initializationDidFail:myErrorMessage];
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
        if (IsOfflineMode) {
            if (!self.isInitializationError) {
                self.isInitializationError = YES;
                NSString *errorMessage = [NSString stringWithFormat:@"OfflineMode enabled, but no saved image found: %@", savedDataPath];
                NSLog(@"%@", errorMessage);
                [self initializationDidFail:errorMessage];
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
                     [self initializationDidFail:myErrorMessage];
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
        if ([achievementDict[@"Player"][@"Gamertag"] isEqualToString:gamertag]) {
            [filtered addObject:achievementDict];
        }
    }
    return [Achievement achievementsWithArray:filtered];
}

-(Achievement *) achievementWithGamertag:(NSString *)gamertag withGameName:(NSString *)gameName withAchievementName:(NSString *)achievementName
{
    for (NSDictionary *achievementDict in self.achievementsFromJSON) {
        if ([achievementDict[@"Player"][@"Gamertag"] isEqualToString:gamertag]) {
            if ([achievementDict[@"Game"][@"Name"] isEqualToString:gameName]) {
                if ([achievementDict[@"Achievement"][@"Name"] isEqualToString:achievementName]) {
                    return [[Achievement alloc] initWithDictionary:achievementDict];
                }
            }
        }
    }
    return nil;
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


#pragma mark - Prep Data for Demo

-(void)prepDataForDemo
{
    // Reference: online links to avatar and gamerpic look like this
    // https://avatar-ssl.xboxlive.com/avatar/GAMERTAG/avatarpic-l.png
    // https://avatar-ssl.xboxlive.com/avatar/GAMERTAG/avatar-body.png
    // Manually download replacement images to the app bundle.
    NSDictionary *cannedImagesForGamertag = @{
      @"Ariock II":         @{ @"gamerpic": @"TempGamerImage2.png" },
      @"MyRazzleDazzle":    @{ @"gamerpic": @"TempGamerImage3.png"},
      @"sbCaliban":         @{ @"gamerpic": @"TempGamerImage4.png"},
      @"Freelancer":        @{ @"gamerpic": @"TempGamerImage5.png"},
      };
      
    for (NSDictionary *profileDict in self.friendProfilesUnsorted) {
        NSString *gamertag = profileDict[@"Player"][@"Gamertag"];
        
        if (cannedImagesForGamertag[gamertag]) {
            // Delete downloaded images and replace with canned images from the app bundle.
            [self replaceDownloadedImage:profileDict[@"Player"][@"Avatar"][@"Body"]
                         withCannedImage:cannedImagesForGamertag[gamertag][@"avatar"]];
            [self replaceDownloadedImage:profileDict[@"Player"][@"Avatar"][@"Gamerpic"][@"Large"]
                         withCannedImage:cannedImagesForGamertag[gamertag][@"gamerpic"]];
        }
    }
    
    
}

-(void) replaceDownloadedImage:(NSString *)url withCannedImage:(NSString *)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *imagePath = [XboxLiveClient filePathForImageUrl:url];
    NSString *canned_image_name = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
    
    NSError *error;
    [fileManager removeItemAtPath:imagePath error: &error];
    if (error) {
        NSLog(@"Error deleting %@", imagePath);
    }
    [fileManager copyItemAtPath:canned_image_name toPath:imagePath error:&error];
    if (error) {
        NSLog(@"Error copying %@ to %@", canned_image_name, imagePath);
    }
    
}

- (NSMutableArray *)prepFriendsListForDemo:(NSMutableArray *)friendGamertags
{
    // Replace friends who have private histories with gamers who are public.
    NSDictionary *swapFriends = @{ @"Laprunminta": @"Freelancer",
                                   @"UnabatedLake1": @"Ariock II"};
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSString *gamertag in friendGamertags) {
        if (swapFriends[gamertag]) {
            [result addObject:swapFriends[gamertag]];
        } else {
            [result addObject:gamertag];
        }
    }
    return result;
}

- (NSArray *)prepGamesListForDemo:(NSArray *)gameDicts withGamertag:gamertag
{
    NSDictionary *filterGames = @{ @"ambroy": @[ @"Diablo III"],
                                   @"Freelancer": @[ @"BioShock Infinite"],
                                   @"sbCaliban": @[ @"Gears of War 2"],
                                   @"Ariock II": @[ @"Peggle"],
                                   @"MyRazzleDazzle": @[ @"Halo 4"],
                                   @"JGailor": @[ @"Skyrim"],
                                   };
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (filterGames[gamertag]) {
        for (NSDictionary *gameDict in gameDicts) {
            NSString *gameName = gameDict[@"Name"];
            // If we have a filter for this gamertag, only include those games.
            if ([filterGames[gamertag] containsObject:gameName]) {
                [result addObject:gameDict];
            }
        }
        return result;
    }
    
    return gameDicts;
}

- (NSMutableArray *)prepAchievementsForDemo:(NSMutableArray *)achievementDicts withGamertag:gamertag withGame:gameDict
{
    // Simulate each gamer getting an achievement every week, starting yesterday.
    static int hoursAgoIncrement = (7 * 24);
    int hoursAgo = 24;
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in achievementDicts) {
        NSMutableDictionary *mdict = [[NSMutableDictionary alloc] initWithDictionary:dict];
    
        // Skip hidden achievements.
        if (![mdict[@"IsHidden"] boolValue]) {
            
            long unlocked = [mdict[@"EarnedOn-UNIX"] boolValue];
            if (unlocked) {
                // Use deterministic but random-looking offset to make achievements less evenly spaced.
                int offset = [gameDict[@"ID"] intValue] % hoursAgoIncrement;
                int timeAgoInSeconds = (hoursAgo * 3600) + (offset * 3600);
                hoursAgo += hoursAgoIncrement + offset;
                NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
                NSDate *earnedOn = [NSDate dateWithTimeIntervalSince1970:interval - timeAgoInSeconds];
                mdict[@"EarnedOn-UNIX"] = [NSString stringWithFormat:@"%f", [earnedOn timeIntervalSince1970]];
                [result addObject:mdict];
            }
        }
    }
    return result;
}

@end




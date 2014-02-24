//
//  ParseClient.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/23/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "ParseClient.h"
#import "Comment.h"

NSString * const ParseClientDidInitNotification = @"ParseClientDidInitNotification";

@interface ParseClient ()

// Interface methods return data from these properties.
@property NSMutableDictionary *commentsForGamertagForGame;
@property NSMutableDictionary *likesForGamertagForGame;

// Used internally during initialization.
@property NSMutableArray *pendingRequests;
@property BOOL isInitializationError;
@property NSString *userGamertag;
@property NSDate *startInit;
@property NSDate *endInit;
@property NSTimeInterval secondsToInit;
@property int totalComments;
@property int totalLikes;

- (void) fetchCommentsWithProfile:(Profile *)profile withGame:(Game *)game;
- (void) fetchLikesWithProfile:(Profile *)profile withGame:(Game *)game;

@end

@implementation ParseClient

static ParseClient *Instance;
static BOOL IsOfflineMode;

+(ParseClient *)instance
{
    @synchronized(self) {
        if (!Instance) {
            Instance = [[ParseClient alloc] init];
        }
    }
    return Instance;
}

+(void)resetInstance
{
    @synchronized(self) {
        // Destroy old instance by overwriting with an uninitialized one.
        NSLog(@"Destroyed instance of ParseClient initialized for %@.", Instance.userGamertag);
        Instance = [[ParseClient alloc] init];
    }
}

+(BOOL)isOfflineMode { return IsOfflineMode; }
+(void)setIsOfflineMode:(BOOL)isOfflineMode { IsOfflineMode = isOfflineMode; }

- (void) initInstance:(Profile *)userProfile withProfiles:(NSArray *)friendProfiles
{
    self.userGamertag = userProfile.gamertag;
    NSLog(@"ParseClient initializing %@with gamertag %@",
          (IsOfflineMode) ? @"in OFFLINE MODE " : @"", self.userGamertag);
    self.startInit = [NSDate date];
    
    self.pendingRequests = [[NSMutableArray alloc] init];
    self.commentsForGamertagForGame = [[NSMutableDictionary alloc] init];
    self.commentsForGamertagForGame[userProfile.gamertag] = [[NSMutableDictionary alloc] init];
    self.likesForGamertagForGame = [[NSMutableDictionary alloc] init];
    self.likesForGamertagForGame[userProfile.gamertag] = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *profiles = [[NSMutableArray alloc] initWithArray:friendProfiles];
    [profiles insertObject:userProfile atIndex:0];
    
    for (Profile *profile in profiles) {
        for (Game *game in profile.recentGames) {
            
            [self fetchCommentsWithProfile:profile withGame:game];
            [self fetchLikesWithProfile:profile withGame:game];
        }
    }
    
}

- (void) fetchCommentsWithProfile:(Profile *)profile withGame:(Game *)game
{
    //NSLog(@"Fetching comments for %@'s achievements for game %@", profile.gamertag, game.name);  // DEBUG
    
    PFQuery *query = [PFQuery queryWithClassName:[Comment parseClassName]];
    [query whereKey:@"achievementGamertag" equalTo:profile.gamertag];
    [query whereKey:@"gameName" equalTo:game.name];

    // Pass the result array into the block (accessing the dict gives us Parse warning).
    self.commentsForGamertagForGame[profile.gamertag][game.name] = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *gameDict = self.commentsForGamertagForGame[profile.gamertag][game.name];

    [self.pendingRequests addObject:query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {

        if (!error) {
            for (Comment *comment in objects) {
                if (!gameDict[comment.achievementName]) {
                    gameDict[comment.achievementName] = [[NSMutableArray alloc] init];
                }
                [gameDict[comment.achievementName] addObject:comment];
            }
            int count = [objects count];
            self.totalComments += count;
            NSLog(@"Added %i comments for %@ for game %@", count, profile.gamertag, game.name);
        } else {
            NSLog(@"ParseClient download error for %@ game %@: %@", profile.gamertag, game.name, [error userInfo][@"error"]);
        }
        [self.pendingRequests removeObject:query];
        [self checkPendingRequests];
    }];
    
}

- (void) fetchLikesWithProfile:(Profile *)profile withGame:(Game *)game
{
    //NSLog(@"Fetching likes for %@'s achievements for game %@", profile.gamertag, game.name);  // DEBUG
    
    PFQuery *query = [PFQuery queryWithClassName:[Like parseClassName]];
    [query whereKey:@"achievementGamertag" equalTo:profile.gamertag];
    [query whereKey:@"gameName" equalTo:game.name];
    
    // Pass the result array into the block (accessing the dict gives us Parse warning).
    self.likesForGamertagForGame[profile.gamertag][game.name] = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *gameDict = self.likesForGamertagForGame[profile.gamertag][game.name];
    
    [self.pendingRequests addObject:query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error) {
            for (Like *like in objects) {
                if (!gameDict[like.achievementName]) {
                    gameDict[like.achievementName] = [[NSMutableArray alloc] init];
                }
                [gameDict[like.achievementName] addObject:like];
            }
            int count = [objects count];
            self.totalLikes += count;
            NSLog(@"Added %i likes for %@ for game %@", count, profile.gamertag, game.name);
        } else {
            NSLog(@"ParseClient download error for %@ game %@: %@", profile.gamertag, game.name, [error userInfo][@"error"]);
        }
        [self.pendingRequests removeObject:query];
        [self checkPendingRequests];
    }];
    
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

- (void) requestsDidComplete
{
    self.endInit = [NSDate date];
    self.secondsToInit = [self.endInit timeIntervalSinceDate:self.startInit];
    
    NSLog(@"ParseClient initialized %@for %@ with %i comments and %i likes (%0.f seconds)",
          (IsOfflineMode) ? @"in OFFLINE MODE " : @"", self.userGamertag, self.totalComments, self.totalLikes, self.secondsToInit);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ParseClientDidInitNotification object:nil];
}

- (NSArray *) commentsForAchievement:(Achievement *)achievement
{
    return self.commentsForGamertagForGame[achievement.gamertag][achievement.gameName][achievement.name];
}

- (NSArray *) likesForAchievement:(Achievement *)achievement
{
    NSArray *array = self.likesForGamertagForGame[achievement.gamertag][achievement.gameName][achievement.name];
    return array;
    //return self.likesForGamertagForGame[achievement.gamertag][achievement.gameName][achievement.name];
}

- (void) saveComment:(Comment *)comment
{
    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Comment uploaded: \"%@\" by %@ on %@", comment.content, comment.authorGamertag, comment.timestamp);
        } else {
            NSLog(@"Error: %@", [error userInfo][@"error"]);
        }
    }];
}

- (void) saveLike:(Like *)like
{
    [like saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Like uploaded by %@ on %@", like.authorGamertag, like.timestamp);
        } else {
            NSLog(@"Error: %@", [error userInfo][@"error"]);
        }
    }];
}


@end

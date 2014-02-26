//
//  ParseClient.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/23/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "ParseClient.h"
#import "Comment.h"
#import <Parse/Parse.h>

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
    self.likesForGamertagForGame = [[NSMutableDictionary alloc] init];
    
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
    if (!self.commentsForGamertagForGame[profile.gamertag]) {
        self.commentsForGamertagForGame[profile.gamertag] = [[NSMutableDictionary alloc] init];
    }
    
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
    if (!self.likesForGamertagForGame[profile.gamertag]) {
        self.likesForGamertagForGame[profile.gamertag] = [[NSMutableDictionary alloc] init];
    }
    
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

#pragma mark - interface methods

- (NSMutableArray *) commentsForAchievement:(Achievement *)achievement
{
    NSMutableArray *array = self.commentsForGamertagForGame[achievement.gamertag][achievement.gameName][achievement.name];
    NSMutableArray *copy = [[NSMutableArray alloc] initWithArray:array];
    return copy;
}

- (NSMutableArray *) likesForAchievement:(Achievement *)achievement
{
    NSMutableArray *array = self.likesForGamertagForGame[achievement.gamertag][achievement.gameName][achievement.name];
    NSMutableArray *copy = [[NSMutableArray alloc] initWithArray:array];
    return copy;
}

- (void) saveComment:(Comment *)comment
{
    NSMutableDictionary *gameDict = self.commentsForGamertagForGame[comment.achievementGamertag][comment.gameName];
    if (!gameDict[comment.achievementName]) {
        gameDict[comment.achievementName] = [[NSMutableArray alloc] init];
    }
    [gameDict[comment.achievementName] addObject:comment];
    
    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Comment on %@:%@:%@ saved", comment.achievementGamertag, comment.gameName, comment.achievementName);
        } else {
            NSLog(@"Error saving Comment on %@:%@:%@ : %@", comment.achievementGamertag, comment.gameName, comment.achievementName, [error userInfo][@"error"]);
        }
    }];
}

- (void) saveLike:(Like *)like
{
    NSMutableDictionary *gameDict = self.likesForGamertagForGame[like.achievementGamertag][like.gameName];
    if (!gameDict[like.achievementName]) {
        gameDict[like.achievementName] = [[NSMutableArray alloc] init];
    }
    [gameDict[like.achievementName] addObject:like];
    
    [like saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Like %@:%@:%@ saved", like.achievementGamertag, like.gameName, like.achievementName);
        } else {
            NSLog(@"Error saving Like %@:%@:%@ : %@", like.achievementGamertag, like.gameName, like.achievementName, [error userInfo][@"error"]);
        }
    }];
}

- (void) deleteComment:(Comment *)comment
{
    NSMutableDictionary *gameDict = self.commentsForGamertagForGame[comment.achievementGamertag][comment.gameName];
    [gameDict[comment.achievementName] removeObject:comment];
    [comment deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Comment %@:%@:%@ deleted", comment.achievementGamertag, comment.gameName, comment.achievementName);
        } else {
            NSLog(@"Error deleting Comment %@:%@:%@ : %@", comment.achievementGamertag, comment.gameName, comment.achievementName, [error userInfo][@"error"]);
        }
    }];
}

- (void) deleteLike:(Like *)like
{
    NSMutableDictionary *gameDict = self.likesForGamertagForGame[like.achievementGamertag][like.gameName];
    [gameDict[like.achievementName] removeObject:like];
    [like deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Like %@:%@:%@ deleted", like.achievementGamertag, like.gameName, like.achievementName);
        } else {
            NSLog(@"Error deleting Like %@:%@:%@ : %@", like.achievementGamertag, like.gameName, like.achievementName, [error userInfo][@"error"]);
        }
    }];
}


+ (void)sendPushNotification:(NSString *)action withAchievement:(Achievement *)achievement
{
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"deviceType" equalTo:@"ios"];
    [pushQuery whereKey:@"gamertag" equalTo:achievement.gamertag];
    NSString *message = [NSString stringWithFormat:@"%@ %@ your achievement %@: %@",
                         [User currentUser].gamerTag, action, achievement.gameName, achievement.name];
    //[PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:message];
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          message, @"alert",
                          //@"Increment", @"badge",
                          //@"cheering.caf", @"sound",
                          achievement.gamertag, @"gamertag",
                          achievement.gameName, @"gameName",
                          achievement.name, @"achievementName",
                          nil];
    PFPush *push = [[PFPush alloc] init];
    [push setData:data];
    [push setQuery:pushQuery];
    [push sendPushInBackground];
    NSLog(@"Sent Push Notification for %@:%@:%@", data[@"gamertag"], data[@"gameName"], data[@"achievementName"]);
    
}


@end

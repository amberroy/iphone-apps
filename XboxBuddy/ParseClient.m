//
//  ParseClient.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/23/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "ParseClient.h"
#import "Comment.h"

@interface ParseClient ()

// Interface methods return data from these properties.
@property NSMutableDictionary *commentsForPlayerForGame;

// Used internally during initialization.
@property NSMutableArray *pendingRequests;
@property BOOL isInitializationError;
@property NSString *userGamertag;
@property NSDate *startInit;
@property NSDate *endInit;
@property NSTimeInterval secondsToInit;
@property int totalComments;

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
    self.commentsForPlayerForGame = [[NSMutableDictionary alloc] init];
    self.commentsForPlayerForGame[userProfile.gamertag] = [[NSMutableDictionary alloc] init];
    
    for (Game *game in userProfile.recentGames) {
        self.commentsForPlayerForGame[userProfile.gamertag][game.name] = [[NSMutableArray alloc] init];
        
        PFQuery *query = [PFQuery queryWithClassName:[Comment parseClassName]];
        [query whereKey:@"achievementGamertag" equalTo:userProfile.gamertag];
        [query whereKey:@"gameName" equalTo:game.name];
    
        NSLog(@"Fetching comments for %@'s achievements for game %@", userProfile.gamertag, game.name);  // DEBUG
        [self.pendingRequests addObject:query];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            if (!error) {
                for (Comment *comment in objects) {
                    [self.commentsForPlayerForGame[userProfile.gamertag][game.name] addObject:comment];
                }
                int count = [objects count];
                self.totalComments += count;
                NSLog(@"Added %i comments for %@'s achievements for game %@", count, userProfile.gamertag, game.name);
            } else {
                NSLog(@"ParseClient download error for %@ game %@: %@", userProfile.gamertag, game.name, [error userInfo][@"error"]);
            }
            [self.pendingRequests removeObject:query];
            [self checkPendingRequests];
        }];
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

- (void) requestsDidComplete
{
    self.endInit = [NSDate date];
    self.secondsToInit = [self.endInit timeIntervalSinceDate:self.startInit];
    
    NSLog(@"ParseClient initialized %@for %@ with %i comments (%0.f seconds)",
          (IsOfflineMode) ? @"in OFFLINE MODE " : @"", self.userGamertag, self.totalComments, self.secondsToInit);
}

- (NSArray *) commentsForAchievement:(Achievement *)achievement
{
    return self.commentsForPlayerForGame[achievement.gamertag][achievement.gameName];
}

- (NSArray *) likesForAchievement:(Achievement *)achievement
{
    // TODO: implement likesForAchievement
    return nil;
}

- (void) saveComment:(Comment *)comment
{
    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSString *content = comment.content;
            if (comment.content.length > 50) {
                // Truncate long comments so they don't clutter our log.
                content = [NSString stringWithFormat:@"%@ ...", [content substringToIndex:49]];
            }
            NSLog(@"Comment uploaded: \"%@\" by %@ on %@", content, comment.authorGamertag, comment.timestamp);
        } else {
            NSLog(@"Error: %@", [error userInfo][@"error"]);
        }
    }];
}

- (void) saveLike:(Like *)like
{
    // TODO: implement saveLikes
    
}


@end

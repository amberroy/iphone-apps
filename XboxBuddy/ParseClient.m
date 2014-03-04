//
//  ParseClient.m
//  XboxBuddy
//
//  Created by Amber Roy on 2/23/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "ParseClient.h"
#import <Parse/Parse.h>

NSString * const ParseClientDidInitNotification = @"ParseClientDidInitNotification";

@interface ParseClient ()

// Interface methods return data from these properties.
@property NSMutableDictionary *commentsForGamertagForGame;
@property NSMutableDictionary *likesForGamertagForGame;
@property NSMutableDictionary *invitationsForGamertag;
@property NSMutableDictionary *usersForGamertag;

// Used internally during initialization.
@property NSMutableArray *pendingRequests;
@property BOOL isInitializationError;
@property NSString *userGamertag;
@property NSDate *startInit;
@property NSDate *endInit;
@property NSTimeInterval secondsToInit;
@property int totalComments;
@property int totalLikes;

- (void) fetchCommentsWithGamertag:(NSString*)gamertag withGame:(Game *)game;
- (void) fetchLikesWithGamertag:(NSString *)gamertag withGame:(Game *)game;
- (void) fetchInvitations;
- (void) fetchUserWithGamertag:(NSString *)gamertag;

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

- (void) registerInstallation
{
    NSString *gamertag = [User currentUser].gamertag;
    if (gamertag) {
        [[PFInstallation currentInstallation] setObject:gamertag forKey:@"gamertag"];
        [[PFInstallation currentInstallation] saveEventually];
        NSLog(@"Registering this Parse Installation to gamertag %@", gamertag);
    }
}

- (void) initInstance:(Profile *)userProfile withProfiles:(NSArray *)friendProfiles
{
    self.userGamertag = userProfile.gamertag;
    NSLog(@"ParseClient initializing %@with gamertag %@",
          (IsOfflineMode) ? @"in OFFLINE MODE " : @"", self.userGamertag);
    self.startInit = [NSDate date];
    
    self.pendingRequests = [[NSMutableArray alloc] init];
    self.commentsForGamertagForGame = [[NSMutableDictionary alloc] init];
    self.likesForGamertagForGame = [[NSMutableDictionary alloc] init];
    self.invitationsForGamertag = [[NSMutableDictionary alloc] init];
    self.usersForGamertag = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *profiles = [[NSMutableArray alloc] initWithArray:friendProfiles];
    [profiles insertObject:userProfile atIndex:0];
    
    for (Profile *profile in profiles) {
        for (Game *game in profile.recentGames) {
            
            [self fetchCommentsWithGamertag:profile.gamertag withGame:game];
            [self fetchLikesWithGamertag:profile.gamertag withGame:game];
            [self fetchUserWithGamertag:profile.gamertag];
        }
    }
    [self fetchInvitations];
    
}

- (void) fetchCommentsWithGamertag:(NSString *)gamertag withGame:(Game *)game
{
    //NSLog(@"Fetching comments for %@'s achievements for game %@", gamertag, game.name);  // DEBUG
    if (!self.commentsForGamertagForGame[gamertag]) {
        self.commentsForGamertagForGame[gamertag] = [[NSMutableDictionary alloc] init];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:[Comment parseClassName]];
    [query whereKey:@"achievementGamertag" equalTo:gamertag];
    [query whereKey:@"gameID" equalTo:game.gameID];

    // Pass the result array into the block (accessing the dict gives us Parse warning).
    self.commentsForGamertagForGame[gamertag][game.gameID] = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *gameDict = self.commentsForGamertagForGame[gamertag][game.gameID];

    [self.pendingRequests addObject:query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {

        if (!error) {
            for (Comment *comment in objects) {
                if (!gameDict[comment.achievementID]) {
                    gameDict[comment.achievementID] = [[NSMutableArray alloc] init];
                }
                [gameDict[comment.achievementID] addObject:comment];
            }
            int count = (int)[objects count];
            self.totalComments += count;
            if (count > 0) {
                NSLog(@"Added %i comments for %@ for game %@", count, gamertag, game.name);
            }
        } else {
            NSLog(@"ParseClient download error for %@ game %@: %@", gamertag, game.name, [error userInfo][@"error"]);
        }
        [self.pendingRequests removeObject:query];
        [self checkPendingRequests];
    }];
    
}

- (void) fetchLikesWithGamertag:(NSString *)gamertag withGame:(Game *)game
{
    //NSLog(@"Fetching likes for %@'s achievements for game %@", gamertag, game.name);  // DEBUG
    if (!self.likesForGamertagForGame[gamertag]) {
        self.likesForGamertagForGame[gamertag] = [[NSMutableDictionary alloc] init];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:[Like parseClassName]];
    [query whereKey:@"achievementGamertag" equalTo:gamertag];
    [query whereKey:@"gameID" equalTo:game.gameID];
    
    // Pass the result array into the block (accessing the dict gives us Parse warning).
    self.likesForGamertagForGame[gamertag][game.gameID] = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *gameDict = self.likesForGamertagForGame[gamertag][game.gameID];
    
    [self.pendingRequests addObject:query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    
        if (!error) {
            NSMutableArray *authors = [[NSMutableArray alloc] init];
            for (Like *like in objects) {
                if (!gameDict[like.achievementID]) {
                    gameDict[like.achievementID] = [[NSMutableArray alloc] init];
                }
                if ([authors containsObject:like.authorGamertag]) {
                    // Somehow a user liked this achievement more than once, delete extra Likes.
                    // Shouldn't happen but Parse will allow it (no unique constraints).
                    NSLog(@"Warning: multiple likes by %@ on %@:%@:%@",
                          like.authorGamertag, like.achievementGamertag, like.gameName, like.achievementName);
                    [self deleteLike:like];
                    continue;
                }
                [authors addObject:like.authorGamertag];
                [gameDict[like.achievementID] addObject:like];
            }
            int count = (int)[objects count];
            self.totalLikes += count;
            if (count > 0) {
                NSLog(@"Added %i likes for %@ for game %@", count, gamertag, game.name);
            }
        } else {
            NSLog(@"ParseClient download error for %@ game %@: %@", gamertag, game.name, [error userInfo][@"error"]);
        }
        [self.pendingRequests removeObject:query];
        [self checkPendingRequests];
    }];
    
}

- (void) fetchInvitations
{
    NSString *gamertag = [User currentUser].gamertag;
    PFQuery *query = [PFQuery queryWithClassName:[Invitation parseClassName]];
    [query whereKey:@"senderGamertag" equalTo:gamertag];
    
    [self.pendingRequests addObject:query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (Invitation *invitation in objects) {
                self.invitationsForGamertag[invitation.recipientGamertag] = invitation;
            }
            int count = (int)[objects count];
            NSLog(@"Added %i Invitations for %@", count, gamertag);
        } else {
            NSLog(@"ParseClient download error for %@ Invitations: %@", gamertag, [error userInfo][@"error"]);
        }
        [self.pendingRequests removeObject:query];
        [self checkPendingRequests];
    }];
}

- (void) fetchUserWithGamertag:(NSString *)gamertag
{
    PFQuery *query = [PFQuery queryWithClassName:[User parseClassName]];
    [query whereKey:@"gamertag" equalTo:gamertag];
    
    [self.pendingRequests addObject:query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (User *user in objects) {
                if (!self.usersForGamertag[gamertag]) {
                    self.usersForGamertag[gamertag] = user;
                } else {
                    // Somehow we have two user objects with this gamertag, delete extras.
                    // Shouldn't happen but Parse will allow it (no unique constraints).
                    NSLog(@"Warning: multiple user objects saved for %@", gamertag);
                    [self deleteUser:user];
                    continue;
                }
            }
            if ([objects count] > 0) {
                NSLog(@"User %@ has used our app", gamertag);
            } else {
                NSLog(@"User %@ has not used our app", gamertag);
                if ([[User currentUser].gamertag isEqualToString:gamertag]) {
                    [self saveUser:[User currentUser]];
                }
            }
        } else {
            NSLog(@"ParseClient download error for %@ Invitations: %@", gamertag, [error userInfo][@"error"]);
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
    NSMutableArray *array = self.commentsForGamertagForGame[achievement.gamertag][achievement.game.gameID][achievement.achievementID];
    NSMutableArray *copy = [[NSMutableArray alloc] initWithArray:array];
    return copy;
}

- (NSMutableArray *) likesForAchievement:(Achievement *)achievement
{
    NSMutableArray *array = self.likesForGamertagForGame[achievement.gamertag][achievement.game.gameID][achievement.achievementID];
    NSMutableArray *copy = [[NSMutableArray alloc] initWithArray:array];
    return copy;
}

- (Invitation *) invitationForGamertag:(NSString *)gamertag
{
    return self.invitationsForGamertag[gamertag];
}

- (User *) userForGamertag:(NSString *)gamertag
{
    return self.usersForGamertag[gamertag];
}

- (void) saveComment:(Comment *)comment
{
    NSMutableDictionary *gameDict = self.commentsForGamertagForGame[comment.achievementGamertag][comment.gameID];
    if (!gameDict[comment.achievementID]) {
        gameDict[comment.achievementID] = [[NSMutableArray alloc] init];
    }
    [gameDict[comment.achievementID] addObject:comment];
    
    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Saved Comment on %@:%@:%@", comment.achievementGamertag, comment.gameName, comment.achievementName);
        } else {
            NSLog(@"Error saving Comment on %@:%@:%@ : %@", comment.achievementGamertag, comment.gameName, comment.achievementName, [error userInfo][@"error"]);
        }
    }];
}

- (void) saveLike:(Like *)like
{
    NSMutableDictionary *gameDict = self.likesForGamertagForGame[like.achievementGamertag][like.gameID];
    if (!gameDict[like.achievementID]) {
        gameDict[like.achievementID] = [[NSMutableArray alloc] init];
    }
    [gameDict[like.achievementID] addObject:like];
    
    [like saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Saved Like %@:%@:%@", like.achievementGamertag, like.gameName, like.achievementName);
        } else {
            NSLog(@"Error saving Like %@:%@:%@ : %@", like.achievementGamertag, like.gameName, like.achievementName, [error userInfo][@"error"]);
        }
    }];
}

- (void) saveInvitation:(Invitation *)invitation
{
    self.invitationsForGamertag[invitation.recipientGamertag] = invitation;
    [invitation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Saved Invitation to %@", invitation.recipientGamertag);
        } else {
            NSLog(@"Error saving Invitation to %@: %@", invitation.recipientGamertag, [error userInfo][@"error"]);
        }
    }];
}
- (void) saveUser:(User *)user
{
    self.usersForGamertag[user.gamertag] = user;
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Saved User %@", user.gamertag);
        } else {
            NSLog(@"Error saving User %@", user.gamertag);
        }
    }];
}

- (void) deleteComment:(Comment *)comment
{
    NSMutableDictionary *gameDict = self.commentsForGamertagForGame[comment.achievementGamertag][comment.gameID];
    [gameDict[comment.achievementID] removeObject:comment];
    [comment deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Deleted Comment %@:%@:%@", comment.achievementGamertag, comment.gameName, comment.achievementName);
        } else {
            NSLog(@"Error deleting Comment %@:%@:%@ : %@", comment.achievementGamertag, comment.gameName, comment.achievementName, [error userInfo][@"error"]);
        }
    }];
}

- (void) deleteLike:(Like *)like
{
    NSMutableDictionary *gameDict = self.likesForGamertagForGame[like.achievementGamertag][like.gameID];
    [gameDict[like.achievementID] removeObject:like];
    [like deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Deleted Like %@:%@:%@", like.achievementGamertag, like.gameName, like.achievementName);
        } else {
            NSLog(@"Error deleting Like %@:%@:%@ : %@", like.achievementGamertag, like.gameName, like.achievementName, [error userInfo][@"error"]);
        }
    }];
}

- (void) deleteInvitation:(Invitation *)invitation
{
    [self.invitationsForGamertag removeObjectForKey:invitation.recipientGamertag];
    [invitation deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Deleted Invitation to %@", invitation.recipientGamertag);
        } else {
            NSLog(@"Error deleting Invitation to %@: %@", invitation.recipientGamertag, [error userInfo][@"error"]);
        }
    }];
}

- (void) deleteUser:(User *)user
{
    [self.usersForGamertag removeObjectForKey:user.gamertag];
    [user deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Deleted User %@", user.gamertag);
        } else {
            NSLog(@"Error deleting User %@", user.gamertag);
        }
    }];
}

+ (void)sendPushNotification:(NSString *)action withAchievement:(Achievement *)achievement
{
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"deviceType" equalTo:@"ios"];
    [pushQuery whereKey:@"gamertag" equalTo:achievement.gamertag];
    NSString *message = [NSString stringWithFormat:@"%@ %@ your achievement %@: %@",
                         [User currentUser].gamertag, action, achievement.game.name, achievement.name];
    //[PFPush sendPushMessageToQueryInBackground:pushQuery withMessage:message];
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          message, @"alert",
                          //@"Increment", @"badge",
                          //@"cheering.caf", @"sound",
                          achievement.gamertag, @"gamertag",
                          achievement.game.name, @"gameName",
                          achievement.name, @"achievementName",
                          nil];
    PFPush *push = [[PFPush alloc] init];
    [push setData:data];
    [push setQuery:pushQuery];
    [push sendPushInBackground];
    NSLog(@"Sent Push Notification for %@:%@:%@", data[@"gamertag"], data[@"gameName"], data[@"achievementName"]);
    
}


@end

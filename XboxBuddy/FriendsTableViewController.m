//
//  FriendsTableViewController.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/4/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "FriendsTableViewController.h"
#import "XboxLiveClient.h"
#import "FriendCell.h"
#import "Profile.h"
#import "UserTableViewController.h"
#import "HomeTableViewController.h"

@interface FriendsTableViewController ()

@property (nonatomic, strong) NSArray *friends;

@end

@implementation FriendsTableViewController

- (void)setup {
    self.friends = [[XboxLiveClient instance] friendProfiles];
    [HomeTableViewController customizeNavigationBar:self];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // TODO: temporary call to setup, doing this here for now to pick up the data after its been initially loaded
    [self setup];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FriendCell";

    FriendCell *cell = (FriendCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Profile *profile = self.friends[indexPath.row];
    [cell initWithProfile:profile];

    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"showUserDetail"]) {

        UITableViewCell *selectedCell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:selectedCell];
        Profile *profile = self.friends[indexPath.row];
        UserTableViewController *userViewController = (UserTableViewController *)segue.destinationViewController;

        userViewController.profile = profile;
    }
}

@end

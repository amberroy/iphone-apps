//
//  MasterViewController.m
//  ToDo List
//
//  Created by Amber Roy on 1/21/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "MasterViewController.h"
#import "TodoCell.h"

@interface MasterViewController () {
    NSMutableArray *_todoStrings;
    NSURL *_plist_url;
    BOOL _user_clicked_add;
}

-(int) getParentRow:(UITextField *)textField;

@end

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewTodo:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:app];
    
    _plist_url = [[NSBundle mainBundle] URLForResource:@"todo" withExtension:@"plist"];
    _todoStrings = [[NSMutableArray alloc] initWithContentsOfURL:_plist_url];
    NSLog(@"Loaded Todo List %@ from %@", _todoStrings, _plist_url);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)insertNewTodo:(id)sender
{
    _user_clicked_add = YES;
    if (!_todoStrings) {
        _todoStrings = [[NSMutableArray alloc] init];
    }
    [_todoStrings insertObject:@"" atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _todoStrings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TodoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    cell.textField.text = _todoStrings[indexPath.row];
    if (_user_clicked_add) {
        [cell.textField becomeFirstResponder];
    }
    _user_clicked_add = NO;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_todoStrings removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Insert not needed, since user can add new todo item at top of list and then reorder the list.
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [_todoStrings insertObject:_todoStrings[fromIndexPath.row] atIndex:toIndexPath.row];
    int newIndex = (toIndexPath.row > fromIndexPath.row) ? fromIndexPath.row : fromIndexPath.row + 1;
    [_todoStrings removeObjectAtIndex:newIndex];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"Saving Todo List %@ to %@", _todoStrings, _plist_url);
    [_todoStrings writeToURL:_plist_url atomically:YES];
}

#pragma mark - UITextFieldDelegate

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField
{
    int row = [self getParentRow:textField];
    _todoStrings[row] = textField.text;
    NSLog(@"After editing Todo List is %@", _todoStrings);
    return YES;
}

-(int) getParentRow:(UITextField *)textField
{
    NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in indexPaths) {
        TodoCell *cell = (TodoCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if (cell.textField == textField) {
            NSLog(@"User edited Row %i", indexPath.row);
            return indexPath.row;
        }
    }
    NSLog(@"Warning, Failed to find row for textField %@", textField);
    return 0;
}


@end

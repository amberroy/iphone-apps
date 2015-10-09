//
//  CollectionViewController.m
//  ImageSearch
//
//  Created by Amber Roy on 1/28/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "SearchViewController.h"
#import "ImageCollectionViewCell.h"
#import "UIImageView+AFNetworking.h"

@interface SearchViewController ()

@property (nonatomic, strong) NSMutableArray *imageResults;
@property (nonatomic, strong) NSMutableArray *spinners;
@property (nonatomic, weak) UICollectionView *myCollectionView;

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageResults = [[NSMutableArray alloc] init];
    self.spinners = [[NSMutableArray alloc] init];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCollectionViewCell *cell= [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIActivityIndicatorView *spinner = self.spinners[indexPath.row];
    [spinner startAnimating];
    spinner.center = cell.imageView.center;
    [cell.imageView addSubview:spinner];
    
    __weak ImageCollectionViewCell *weakCell = cell; // Use weak ref in callback.
    NSURL *url = [NSURL URLWithString:self.imageResults[indexPath.row][@"url"]];
    [cell.imageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:url]
        placeholderImage:nil success:
        ^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            weakCell.imageView.image = image;
            [spinner stopAnimating];
            [weakCell setNeedsLayout];
        }
        failure:^(NSURLRequest *req, NSHTTPURLResponse *res, NSError *error) {
        }
     ];
    
    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!self.myCollectionView) {
        self.myCollectionView = collectionView;
    }
    return [self.imageResults count];
}

#pragma mark - UISearchDisplay delegate

//    static NSString *CellIdentifier = @"CellIdentifier";
//
//    // Dequeue or create a cell of the appropriate type.
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    UIImageView *imageView = nil;
//    const int IMAGE_TAG = 1;
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//        cell.accessoryType = UITableViewCellAccessoryNone;
//        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
//        imageView.contentMode = UIViewContentModeScaleAspectFill;
//        imageView.tag = IMAGE_TAG;
//        [cell.contentView addSubview:imageView];
//    } else {
//        imageView = (UIImageView *)[cell.contentView viewWithTag:IMAGE_TAG];
//    }
//
//    // Clear the previous image
//    imageView.image = nil;
//    [imageView setImageWithURL:[NSURL URLWithString:[self.imageResults[indexPath.row] valueForKeyPath:@"url"]]];
//
//    return cell;

#pragma mark - UISearchDisplay delegate

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    [self.imageResults removeAllObjects];
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    return NO;
}

#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:
       @"http://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%@",
       [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
     NSLog(@"Sending request: %@", url);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
    completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         if (connectionError) {
             NSLog(@"ERROR connecting to %@", url);
         } else {
             NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             NSArray *results = response[@"responseData"][@"results"];
             [self.imageResults removeAllObjects];
             [self.imageResults addObjectsFromArray:results];
             //[self.searchDisplayController.searchResultsTableView reloadData];
             NSLog(@"New image result set:");
             for (NSDictionary *dict in self.imageResults) {
                 NSLog(@"%@", dict[@"url"]);
             }
             
             for (NSDictionary *dict in self.imageResults) {
                 [self.spinners addObject:[[UIActivityIndicatorView alloc]
                   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
             }
             
             [self.myCollectionView reloadData];
         }
     }];
    
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    [searchBar resignFirstResponder];
}


@end

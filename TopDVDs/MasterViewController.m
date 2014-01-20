//
//  MasterViewController.m
//  TopDVDs
//
//  Created by Amber Roy on 1/19/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import "MovieCell.h"
#import "UIImageView+AFNetworking.h"

@interface MasterViewController ()

@property NSMutableArray *movieDigests;
@property UIActivityIndicatorView *spinner;
@property NSError *networkingError;

- (void)fetchMovieData;
- (void)extractMovieDigests:(NSDictionary *)dict;

@end

@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.spinner = [[UIActivityIndicatorView alloc]
                    initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = self.view.center;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
    
    [self fetchMovieData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.networkingError) {
        [self.spinner stopAnimating];
        return 1;
    }
    
    if (!self.movieDigests) {
        [self.spinner startAnimating];
        return 0;
    }
    
    [self.spinner stopAnimating];
    return [self.movieDigests count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.networkingError) {
        UITableViewCell *errorCell = [[UITableViewCell alloc]
                                      initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"error"];
        errorCell.textLabel.text = @"Network Error";
        errorCell.detailTextLabel.text = @"Unable to fetch movie data.";
        return errorCell;
    }
    
    MovieCell *cell = (MovieCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSDictionary *movie_digest = self.movieDigests[indexPath.row];
    cell.titleLabel.text = movie_digest[@"title"];
    cell.synopsisLabel.text = movie_digest[@"synopsis"];
    cell.castLabel.text = movie_digest[@"cast"];
    [self fetchImageData:cell fromURL:movie_digest[@"image_url"]];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // HERE
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary *movieDigest = self.movieDigests[indexPath.row];
        [[segue destinationViewController] setDetailItem:movieDigest];
    }
}

#pragma mark - Fetch Data


- (void)fetchMovieData
{
    
    NSString *DVD_URL = @"http://api.rottentomatoes.com/api/public/v1.0/lists/dvds/top_rentals.json?apikey=g9au4hv6khv6wzvzgt55gpqs";
    
    NSURL *url = [NSURL URLWithString:DVD_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSLog(@"Sending request... %@", DVD_URL);
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         
         if (!connectionError) {
             // JSONObjectWithData returns type (id) but we can treat as dict.
             NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             NSLog(@"... got response with %@", [[object allKeys] componentsJoinedByString:@","]);
             self.networkingError = nil;
             [self extractMovieDigests:object];
             [self.tableView reloadData];
         } else {
             self.networkingError = connectionError;
             [self.tableView reloadData];
             NSLog(@"... request failed with error %@", connectionError);
         }
     }
     ];
}

- (void)extractMovieDigests:(NSDictionary *)dict
{
    NSMutableArray *movie_digests = [[NSMutableArray alloc]init];
    
    // Iterate the dicts obtained from JSON serialization.
    NSArray *movies = dict[@"movies"];
    for (NSDictionary *movieDict in movies) {
        NSArray *actors = movieDict[@"abridged_cast"];
        NSMutableArray *actor_names = [[NSMutableArray alloc] init];
        for (NSDictionary *actorDict in actors) {
            [actor_names addObject:actorDict[@"name"]];
        }
        NSString *actors_concat = [actor_names componentsJoinedByString:@", "];
        
        // Digest of the data we care about, in lieu of a full Movie class.
        NSDictionary *dict = @{
                               @"title" : movieDict[@"title"],
                               @"synopsis": movieDict[@"synopsis"],
                               @"cast": actors_concat,
                               //@"image_url": movieDict[@"posters"][@"thumbnail"],
                               @"image_url": movieDict[@"posters"][@"profile"],
                               };
        [movie_digests addObject:dict];
        
    }
    
    self.movieDigests = movie_digests;
}

- (void)fetchImageData:(UITableViewCell *)cell fromURL:(NSString *)image_url
{
    __weak UITableViewCell *weakCell = cell;
    NSURL *url = [[NSURL alloc] initWithString:image_url];
    [cell.imageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:url]
                          placeholderImage:[UIImage imageNamed:@"placeholder.png"] success:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         weakCell.imageView.image = image;
         // setNeedsLayout needed if placeholder not set or diff size than image
         [weakCell setNeedsLayout];
         self.networkingError = nil;
     }
                                   failure:^(NSURLRequest *req, NSHTTPURLResponse *res, NSError *error) {
                                       self.networkingError = error;
                                   }];
}

/*********************************************************
 movies: (
 {
 "abridged_cast" =
 (
 { characters =                 (
 "Clark Kent/Kal-El");
 id = 341817917;
 name = "Henry Cavill";
 },
 { characters =                 (
 "Lois Lane");
 id = 162653029;
 name = "Amy Adams";
 }
 );
 "alternate_ids" =         {
 imdb = 0770828;
 };
 "critics_consensus" = "Man of Steel provides exhilarating action and spectacle to overcome its detours into generic blockbuster territory.";
 id = 770678819;
 links =         {
 alternate = "http://www.rottentomatoes.com/m/superman_man_of_steel/";
 cast = "http://api.rottentomatoes.com/api/public/v1.0/movies/770678819/cast.json";
 clips = "http://api.rottentomatoes.com/api/public/v1.0/movies/770678819/clips.json";
 reviews = "http://api.rottentomatoes.com/api/public/v1.0/movies/770678819/reviews.json";
 self = "http://api.rottentomatoes.com/api/public/v1.0/movies/770678819.json";
 similar = "http://api.rottentomatoes.com/api/public/v1.0/movies/770678819/similar.json";
 };
 "mpaa_rating" = "PG-13";
 posters =         {
 detailed = "http://content9.flixster.com/movie/11/17/42/11174287_det.jpg";
 original = "http://content9.flixster.com/movie/11/17/42/11174287_ori.jpg";
 profile = "http://content9.flixster.com/movie/11/17/42/11174287_pro.jpg";
 thumbnail = "http://content9.flixster.com/movie/11/17/42/11174287_mob.jpg";
 };
 ratings =         {
 "audience_rating" = Upright;
 "audience_score" = 76;
 "critics_rating" = Rotten;
 "critics_score" = 55;
 };
 "release_dates" =         {
 dvd = "2013-11-12";
 theater = "2013-06-14";
 };
 runtime = 143;
 synopsis = "A young boy learns that he has extraordinary powers and is not of this Earth. As a young man, he journeys to discover where he came from and what he was sent here to do. But the hero in him must emerge if he is to save the world from annihilation and become the symbol of hope for all mankind. -- (C) Warner Bros";
 title = "Man of Steel";
 year = 2013;
 },
 {
 "abridged_cast" =         (.......
 
 
 ) // end list of dicts, each one represents one movie.
 
 *********************************************************/

@end

//
//  DetailViewController.m
//  TopDVDs
//
//  Created by Amber Roy on 1/19/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import "DetailViewController.h"
#import "UIImageView+AFNetworking.h"

@interface DetailViewController ()
- (void)configureView;

@property NSDictionary *movieDigest;

@property (weak, nonatomic) IBOutlet UILabel *synopsisLabel;
@property (weak, nonatomic) IBOutlet UILabel *castLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UINavigationItem *navItem;

@property NSError *networkingError;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(NSDictionary *)newDetailItem
{
    if (self.movieDigest != newDetailItem) {
        self.movieDigest = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.movieDigest) {
        self.navItem.title = self.movieDigest[@"title"];
        self.synopsisLabel.text = self.movieDigest[@"synopsis"];
        self.castLabel.text = self.movieDigest[@"cast"];
        [self fetchImageData:self.movieDigest[@"detailed_image_url"]];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Fetch image

- (void)fetchImageData:(NSString *)image_url
{
    __weak UIImageView *weakImageView = self.imageView;
    NSURL *url = [[NSURL alloc] initWithString:image_url];
    [self.imageView setImageWithURLRequest:[[NSURLRequest alloc] initWithURL:url]
                          placeholderImage:[UIImage imageNamed:@"placeholder.png"] success:
     ^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
     {
         weakImageView.image = image;
         // setNeedsLayout needed if placeholder not set or diff size than image
         [weakImageView setNeedsLayout];
         self.networkingError = nil;
     }
                                   failure:^(NSURLRequest *req, NSHTTPURLResponse *res, NSError *error) {
                                       self.networkingError = error;
                                   }];
}

@end

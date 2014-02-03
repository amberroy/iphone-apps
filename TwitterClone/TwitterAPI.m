//
//  TwitterAPI.m
//  TwitterClone
//
//  Created by Amber Roy on 1/26/14.
//  Copyright (c) 2014 Amber Roy. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "TwitterAPI.h"

@interface TwitterAPI ()


- (void)accessTwitterAPI:(TwitterOperation)operation parameters:(NSDictionary *)parameters;

@end


@implementation TwitterAPI


- (void)accessTwitterAPI:(TwitterOperation)operation parameters:(NSDictionary *)parameters
{
    // Example usage: [self accessTwitterAPI:HOME_TIMELINE];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error)
     {
         if (granted == YES)
         {
             NSArray *arrayOfAccounts = [accountStore accountsWithAccountType:accountType];
             if ([arrayOfAccounts count] > 0) {
                 ACAccount *twitterAccount = [arrayOfAccounts lastObject];
                 self.current_username = twitterAccount.username;
                 NSLog(@"Twitter account access granted, proceeding with request.");
                 
                 NSURL *requestURL;
                 SLRequestMethod myRequestMethod = SLRequestMethodGET;
                 NSDictionary  *myParams = parameters;
                 switch (operation) {
                     case HOME_TIMELINE:
                         requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                         myRequestMethod = SLRequestMethodGET;
                         if (!myParams) {
                             myParams = @{ @"count": @"20", @"include_entities": @"1", @"include_my_retweet": @"1"};
                         }
                         break;
                         
                     case SHOW_CURRENT_USER:
                         requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/users/show.json"];
                         myRequestMethod = SLRequestMethodGET;
                         if (!myParams) {
                             myParams = @{ @"screen_name": self.current_username};
                         } else {
                             [myParams setValue:self.current_username forKey:@"screen_name"];
                         }
                         break;
                         
                     case POST_TWEET:
                         requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
                         myRequestMethod = SLRequestMethodPOST;
                         if (!myParams || !myParams[@"status"]) {
                             NSLog(@"Cannot post new Tweet: Failed to specify 'status' parameter.");
                             NSString *errorMessage = @"Cannot post Tweet due to internal error.";
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.delegate twitterDidReturn:nil operation:operation errorMessage:errorMessage];
                             });
                         }
                         break;
                         
                     case POST_RETWEET: {
                         myRequestMethod = SLRequestMethodPOST;
                         if (!myParams || !myParams[@"id"]) {
                             NSLog(@"Cannot retweet: Failed to specify 'id' parameter.");
                             NSString *errorMessage = @"Cannot retweet due to internal error.";
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.delegate twitterDidReturn:nil operation:operation errorMessage:errorMessage];
                             });
                         }
                         NSString *url_string = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweet/%@.json", myParams[@"id"]];
                         NSMutableDictionary *dictWithoutId = [NSMutableDictionary dictionaryWithDictionary:myParams];
                         [dictWithoutId removeObjectForKey:@"id"];
                         myParams = [NSDictionary dictionaryWithDictionary:dictWithoutId];
                         requestURL = [NSURL URLWithString:url_string];
                         break;
                     }
                         
                     case FAVORITES_CREATE:
                         requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/favorites/create.json"];
                         myRequestMethod = SLRequestMethodPOST;
                         if (!myParams || !myParams[@"id"]) {
                             NSLog(@"Cannot favorite the tweet: Failed to specify 'id' parameter.");
                             NSString *errorMessage = @"Cannot favorite tweet due to internal error.";
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.delegate twitterDidReturn:nil operation:operation errorMessage:errorMessage];
                             });
                         }
                         break;
                         
                     case FAVORITES_DESTROY:
                         requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/favorites/destroy.json"];
                         myRequestMethod = SLRequestMethodPOST;
                         if (!myParams || !myParams[@"id"]) {
                             NSLog(@"Cannot unfavorite the tweet: Failed to specify 'id' parameter.");
                             NSString *errorMessage = @"Cannot favorite tweet due to internal error.";
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.delegate twitterDidReturn:nil operation:operation errorMessage:errorMessage];
                             });
                         }
                         break;
                         
                     case RETWEET_DESTROY: {
                         myRequestMethod = SLRequestMethodPOST;
                         if (!myParams || !myParams[@"id"]) {
                             NSLog(@"Cannot unfavorite the tweet: Failed to specify 'id' parameter.");
                             NSString *errorMessage = @"Cannot destroy tweet due to internal error.";
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.delegate twitterDidReturn:nil operation:operation errorMessage:errorMessage];
                             });
                         }
                         NSString *url_string = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/destroy/%@.json", myParams[@"id"]];
                         requestURL = [NSURL URLWithString:url_string];
                         break;
                     }
                         
                     default:
                         NSLog(@"Cannot access Twitter API, unrecognized opeartion: %i", operation);
                         NSString *errorMessage = @"Cannot access Twitter due to internal error.";
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self.delegate twitterDidReturn:nil operation:operation errorMessage:errorMessage];
                         });
                         break;
                 }
                 
                 SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:myRequestMethod URL:requestURL parameters:myParams];
                 postRequest.account = twitterAccount;
                 
                 NSLog(@"Sending request: %@", requestURL);
                 [postRequest performRequestWithHandler: ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
                  {
                      NSArray *dataSource = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
                      if (dataSource.count != 0) {
                          
                          // Uncomment to show respone from Twitter server.
                          NSLog(@"JSON Response: %@", dataSource);
                          [self.delegate twitterDidReturn:dataSource operation:operation errorMessage:nil];
                      } else {
                          NSLog(@"Response contains no data. Error: %@", error);
                      }
                  }];
                 
             } else {
                 NSLog(@"No Twitter Account found on this device.");
                 NSString *errorMessage = @"No Twitter accounts configured.      \n"
                                          @"Go to iOS Home->Settings->Twitter,   \n"
                                          @"Add Account, then retry.";
                 NSLog(@"%@", errorMessage);
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.delegate twitterDidReturn:nil operation:operation errorMessage:errorMessage];
                 });
             }
         } else {
             NSLog(@"Twitter Access not granted for this app.");
             NSString *errorMessage = @"To continue, grant Twitter access.   \n"
                                      @"Go to iOS Home->Settings->Twitter,   \n"
                                      @"scroll down to Allow These Apps,     \n"
                                      @"enable this app, then retry.";
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.delegate twitterDidReturn:nil operation:operation errorMessage:errorMessage];
             });
         }
     }];
}

@end

//{
//    contributors = "<null>";
//    coordinates = "<null>";
//    "created_at" = "Sat Feb 01 00:04:16 +0000 2014";
//    entities =         {
//        hashtags =             (
//                                {
//                                    indices =                     (
//                                                                   4,
//                                                                   7
//                                                                   );
//                                    text = D3;
//                                }
//                                );
//        media =             (
//                             {
//                                 "display_url" = "pic.twitter.com/GvXjMaklt3";
//                                 "expanded_url" = "http://twitter.com/Diablo/status/429404796169113601/photo/1";
//                                 id = 429404796173307904;
//                                 "id_str" = 429404796173307904;
//                                 indices =                     (
//                                                                117,
//                                                                139
//                                                                );
//                                 "media_url" = "http://pbs.twimg.com/media/BfWNYxTCUAA86cc.jpg";
//                                 "media_url_https" = "https://pbs.twimg.com/media/BfWNYxTCUAA86cc.jpg";
//                                 sizes =                     {
//                                     large =                         {
//                                         h = 526;
//                                         resize = fit;
//                                         w = 560;
//                                     };
//                                     medium =                         {
//                                         h = 526;
//                                         resize = fit;
//                                         w = 560;
//                                     };
//                                     small =                         {
//                                         h = 319;
//                                         resize = fit;
//                                         w = 340;
//                                     };
//                                     thumb =                         {
//                                         h = 150;
//                                         resize = crop;
//                                         w = 150;
//                                     };
//                                 };
//                                 type = photo;
//                                 url = "http://t.co/GvXjMaklt3";
//                             }
//                             );
//        symbols =             (
//        );
//        urls =             (
//                            {
//                                "display_url" = "bit.ly/1be7xi7";
//                                "expanded_url" = "http://bit.ly/1be7xi7";
//                                indices =                     (
//                                                               94,
//                                                               116
//                                                               );
//                                url = "http://t.co/RcgF1bEJYV";
//                            }
//                            );
//        "user_mentions" =             (
//        );
//    };
//    "favorite_count" = 78;
//    favorited = 1;
//    geo = "<null>";
//    id = 429404796169113601;
//    "id_str" = 429404796169113601;
//    "in_reply_to_screen_name" = "<null>";
//    "in_reply_to_status_id" = "<null>";
//    "in_reply_to_status_id_str" = "<null>";
//    "in_reply_to_user_id" = "<null>";
//    "in_reply_to_user_id_str" = "<null>";
//    lang = en;
//    place = "<null>";
//    "possibly_sensitive" = 0;
//    "retweet_count" = 75;
//    retweeted = 1;
//    source = web;
//    text = "Our #D3 \"Design a Legendary\" weapon has at last been named. Feast your eyes on Shard of Hate! http://t.co/RcgF1bEJYV http://t.co/GvXjMaklt3";
//    truncated = 0;
//    user =         {
//        "contributors_enabled" = 0;
//        "created_at" = "Tue Jul 28 22:39:00 +0000 2009";
//        "default_profile" = 0;
//        "default_profile_image" = 0;
//        description = "Official @Diablo Updates | Blizzard Entertainment";
//        entities =             {
//            description =                 {
//                urls =                     (
//                );
//            };
//            url =                 {
//                urls =                     (
//                                            {
//                                                "display_url" = "diablo3.com";
//                                                "expanded_url" = "http://www.diablo3.com";
//                                                indices =                             (
//                                                                                       0,
//                                                                                       22
//                                                                                       );
//                                                url = "http://t.co/Afc86ewWCV";
//                                            }
//                                            );
//            };
//        };
//        "favourites_count" = 21;
//        "follow_request_sent" = 0;
//        "followers_count" = 258177;
//        following = 1;
//        "friends_count" = 58;
//        "geo_enabled" = 0;
//        id = 61040833;
//        "id_str" = 61040833;
//        "is_translation_enabled" = 0;
//        "is_translator" = 0;
//        lang = en;
//        "listed_count" = 4543;
//        location = "Irvine, California";
//        name = Diablo;
//        notifications = 0;
//        "profile_background_color" = 000000;
//        "profile_background_image_url" = "http://a0.twimg.com/profile_background_images/378800000056345927/71b2923e4053aeacdf71049cebd91b2d.jpeg";
//        "profile_background_image_url_https" = "https://si0.twimg.com/profile_background_images/378800000056345927/71b2923e4053aeacdf71049cebd91b2d.jpeg";
//        "profile_background_tile" = 0;
//        "profile_banner_url" = "https://pbs.twimg.com/profile_banners/61040833/1377081120";
//        "profile_image_url" = "http://pbs.twimg.com/profile_images/378800000333339638/8cd4150372c3cfdb81e030c814822983_normal.jpeg";
//        "profile_image_url_https" = "https://pbs.twimg.com/profile_images/378800000333339638/8cd4150372c3cfdb81e030c814822983_normal.jpeg";
//        "profile_link_color" = 68919F;
//        "profile_sidebar_border_color" = FFFFFF;
//        "profile_sidebar_fill_color" = F5BC7A;
//        "profile_text_color" = 1F130B;
//        "profile_use_background_image" = 1;
//        protected = 0;
//        "screen_name" = Diablo;
//        "statuses_count" = 5754;
//        "time_zone" = "Pacific Time (US & Canada)";
//        url = "http://t.co/Afc86ewWCV";
//        "utc_offset" = "-28800";
//        verified = 1;
//    };
//},


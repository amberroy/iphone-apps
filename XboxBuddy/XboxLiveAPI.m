//
//  XboxLiveAPI.m
//  XboxBuddy
//
//  Created by Amber Roy on 1/29/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "XboxLiveAPI.h"

@implementation XboxLiveAPI

-(void)accessXboxLiveAPI:(XboxLiveOperation)operation parameters:(NSDictionary *)parameters
{
    
    NSString *url_string;
    switch (operation) {
            
        case XboxLiveProfile:

            if (!parameters || !parameters[@"gamertag"]) {
                NSString *errorMessage = @"Failed to specify 'gamertag' parameter.";
                NSLog(@"%@", errorMessage);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate xboxLiveDidReturn:nil operation:XboxLiveProfile errorMessage:errorMessage];
                });
            }
            url_string = [NSString stringWithFormat:@"http://xboxleaders.com/api/profile.json?gamertag=%@", parameters[@"gamertag"]];
            break;
            
        default:
            break;
    }
                          
    NSURL *url = [NSURL URLWithString:url_string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"Sending request: %@", url);
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler: ^(NSURLResponse *urlResponse, NSData *responseData, NSError *connectionError)
     {
         NSString *errorMessage = nil;
         NSArray *data = nil;
         
         if (connectionError) {
             errorMessage = [NSString stringWithFormat:@"ERROR connecting to %@", url_string];
         } else {
             
             NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
             if (!response) {
                 errorMessage = [NSString stringWithFormat:@"Empty response from %@", url_string];
             } else {
                 if ([response[@"status"] isEqualToString:@"error"]) {
                     errorMessage = response[@"data"][@"message"];
                 } else {
                     // Success!
                     data = response[@"data"];
                 }
             }
             
             if (errorMessage) {
                 NSLog(@"Request did not succeed: %@", errorMessage);
             } else {
                 NSLog(@"Request successful. Freshness: '%@'  Runtime: %@",
                       response[@"data"][@"freshness"], response[@"runtime"]);
                 //NSLog(@"data");            // Uncomment to log response from server.
             }
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.delegate xboxLiveDidReturn:data operation:XboxLiveProfile errorMessage:errorMessage];
             });
         }
     }];
}

@end




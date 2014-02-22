//
//  LoginViewController.m
//  XboxBuddy
//
//  Created by Christine Wang on 2/17/14.
//  Copyright (c) 2014 XboxBuddy. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()

@property (strong, nonatomic) IBOutlet UITextField *gamerTag;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (IBAction)login:(id)sender;

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup the Web View.
    NSString *login_url = @"https://login.live.com/login.srf?wa=wsignin1.0&rpsnv=12&ct=1393090899&rver=6.4.6456.0&wp=MBI_SSL&wreply=https:%2F%2Flive.xbox.com:443%2Fxweb%2Flive%2Fpassport%2FsetCookies.ashx%3Frru%3Dhttps%253a%252f%252flive.xbox.com%252fen-US%252fAccount%252fSignin&lc=1033&id=66262&cbcxt=0";
    
    NSURL *url = [NSURL URLWithString:login_url];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    //self.webView.scalesPageToFit = YES;
    //self.webView.delegate = self;
    [self.webView loadRequest:requestObj];
    

    //[self.gamerTag becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender
{
    [User setCurrentUser:[[User alloc] initWithGamerTag:self.gamerTag.text]];
}

- (IBAction)touchDownLogin:(id)sender {
    [self.gamerTag resignFirstResponder];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    int width = self.view.frame.size.width;
    NSString *jsCode = [NSString stringWithFormat:@"function increaseMaxZoomFactor() { var element = document.createElement('meta'); element.name = \"viewport\"; element.content = \"width=%i\"; var head = document.getElementsByTagName('head')[0]; head.appendChild(element); }", width];
    [webView stringByEvaluatingJavaScriptFromString:jsCode];
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [request.URL absoluteString];
    NSLog(@"loading URL: %@", url);
    
    // TODO: Get gamertag from Profile page.
    //NSString *xbox_home_url = @"https://live.xbox.com/en-US/Profile";
    //NSString *page_source = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
    if ([url isEqual:@"https://live.xbox.com/Signin?id=66262&mkt=EN-US&cbcxt=0"]) {
        // Hide image on left of login form, as well as bottom footer.
        [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('brandModeTD').style.display = 'none'"];
        [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('footerTD').style.display = 'none'"];
    }
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.gamerTag resignFirstResponder];
    return YES;
}


@end

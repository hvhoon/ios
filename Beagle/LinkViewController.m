//
//  LinkViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 26/09/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "LinkViewController.h"

@interface LinkViewController ()<UIWebViewDelegate>
@property(nonatomic,weak)IBOutlet UIWebView*linkWebView;

@end

@implementation LinkViewController
@synthesize linkWebView;
@synthesize linkString;
- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController.navigationBar setTintColor:[[BeagleManager SharedInstance] darkDominantColor]];
    
    [self.linkWebView setScalesPageToFit:YES];
    
    NSString *outputString = [linkString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    
    if ([linkString hasPrefix:@"http://"]||[linkString hasPrefix:@"www"]) {
        //Has Prefix
       [self.linkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:outputString]]];

    }
    else if (([linkString hasSuffix:@"com"]||[linkString hasSuffix:@"buzz"])){
        NSString *prefixString = @"http://www.";
        NSString *searchString = [NSString stringWithFormat:@"%@%@", prefixString, outputString];
        [self.linkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:searchString]]];
        
    }
    else
    {
        //Does not have prefix. Do what you want here. I google it.
        NSString *googleString = @"http://google.com/search?q=";
        NSString *searchString = [NSString stringWithFormat:@"%@%@", googleString, outputString];
        [self.linkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:searchString]]];
        
    }
    
    // Do any additional setup after loading the view.
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"webViewDidFinishLoad");
}
-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"didFailLoadWithError");
}
-(void)webViewDidStartLoad:(UIWebView *)webView{
    NSLog(@"webViewDidStartLoad");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

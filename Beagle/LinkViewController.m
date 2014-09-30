//
//  LinkViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 26/09/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "LinkViewController.h"

@interface LinkViewController ()<UIWebViewDelegate,UIActionSheetDelegate>
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
    else{
        NSString *prefixString = @"http://www.";
        NSString *searchString = [NSString stringWithFormat:@"%@%@", prefixString, outputString];
        [self.linkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:searchString]]];
        
    }
    
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                  target:self
                                                                                 action:@selector(shareButtonPressed:)];
    
    self.navigationItem.rightBarButtonItem=shareButton;
    
    // Do any additional setup after loading the view.
}

- (void)shareButtonPressed:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:linkString delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", @"Copy Link", nil];
    
        if (self.view.superview) {
            [actionSheet showInView:self.view.superview];
        } else {
            [actionSheet showInView:self.view];
        }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && ![[[[self.linkWebView request] URL] absoluteString] isEqualToString:@""]) {
        [[UIApplication sharedApplication] openURL:[[self.linkWebView request] URL]];
    }else if (buttonIndex==1){
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.URL = [[self.linkWebView request] URL];
    }
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

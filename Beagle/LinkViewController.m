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
    [self.linkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:linkString]]];
    // Do any additional setup after loading the view.
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

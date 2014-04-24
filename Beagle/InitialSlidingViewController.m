//
//  InitialSlidingViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "InitialSlidingViewController.h"


@implementation InitialSlidingViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES;
}
-(void)viewDidLoad{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.topViewController =[storyboard instantiateViewControllerWithIdentifier:@"homeScreen"];
    [(AppDelegate*)[[UIApplication sharedApplication] delegate]setListViewController: self.topViewController];

}



@end

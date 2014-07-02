//
//  AboutUsViewController.m
//  Beagle
//
//  Created by Harish Hoon on 7/1/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "AboutUsViewController.h"

@interface AboutUsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *buildText;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation AboutUsViewController

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
    // Do any additional setup after loading the view.
    
    // Extract App Name
    NSDictionary *appMetaData = [[NSBundle mainBundle] infoDictionary];
    NSString* bundleName = [appMetaData objectForKey:@"CFBundleShortVersionString"];
    NSString* buildNumber = [appMetaData objectForKey:@"CFBundleVersion"];
    
    // Build text
    _buildText.text = [NSString stringWithFormat:@"%@ (%@)", bundleName, buildNumber];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)settingsButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
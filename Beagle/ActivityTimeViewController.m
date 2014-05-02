//
//  ActivityTimeViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 02/05/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ActivityTimeViewController.h"
#import "TimeFilterView.h"
#import "CustomPickerView.h"
@interface ActivityTimeViewController ()<UIScrollViewDelegate,TimeFilterDelegate,CustomPickerViewDelegate>
@property(nonatomic,weak)IBOutlet UIScrollView *scrollView;
@end

@implementation ActivityTimeViewController
@synthesize delegate=_delegate;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithRed:162.0/255.0 green:162.0/255.0 blue:162.0/255.0 alpha:1.0]];
    [self.view setAlpha:0.10];
    
    
         [[UIApplication sharedApplication] setStatusBarHidden:YES];
        
        for (int i = 0; i < 2; i++) {
            
            switch (i) {
                case 0:
                {
                    TimeFilterView *filterView = [[TimeFilterView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
                    filterView.delegate=self;
                    [filterView setBackgroundColor:[UIColor clearColor]];
                    [_scrollView addSubview:filterView];
                    
                }
                    
                    
                    
                    break;
                case 1:
                {
                    
                    
                    UIView *customPickerView = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomPickerView" owner:self options:nil];
                    CustomPickerView *view=[nib objectAtIndex:0];
                    view.frame=CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                    view.userInteractionEnabled=YES;
                    
                    customPickerView.userInteractionEnabled=YES;
                    [_scrollView addSubview:customPickerView];
                    [customPickerView addSubview:view];
                    [view buildTheLogic];
                    
                }
                    break;
                    
                    
                default:
                    break;
            }
            
            
        }
        
    _scrollView.contentSize = CGSizeMake(320,2*self.view.frame.size.height);
    
    // Do any additional setup after loading the view.
}
-(void) filterIndex:(NSInteger) index{
    [_delegate dismissactivityTimeFilter:self];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

//
//  SettingsViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 20/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong)IBOutlet UITableView*settingsTableView;
@end

@implementation SettingsViewController
@synthesize settingsTableView=_settingsTableView;
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
    
    [self.slidingViewController setAnchorRightRevealAmount:270.0f];
     self.slidingViewController.underLeftWidthLayout = ECFullWidth;

	// Do any additional setup after loading the view.
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    
    return 7;
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    
    switch (indexPath.row) {
        case 0:
        {
            return 60.5f;
        }
            break;
            
        default:
            
          break;
    }
    return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MediaTableCell";
    
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle=UITableViewCellSelectionStyleNone;
    }
    
    switch (indexPath.row) {
        case 0:
        {
            
            UIImageView *profileImageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 52.5, 52.5)];
            profileImageView.tag=2345;
            [cell.contentView addSubview:profileImageView];
            
            if([[[BeagleManager SharedInstance]beaglePlayer]profileData]==nil){
                
                [self imageCircular:[UIImage imageNamed:@"picbox"]];
                
                
                NSOperationQueue *queue = [NSOperationQueue new];
                NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                                    initWithTarget:self
                                                    selector:@selector(loadProfileImage:)
                                                    object:[[[BeagleManager SharedInstance]beaglePlayer]profileImageUrl]];
                [queue addOperation:operation];
                
            }
            else{
                [self imageCircular:[UIImage imageWithData:[[[BeagleManager SharedInstance]beaglePlayer]profileData]]];
            }
            
        }
            break;
            
        default:
            break;
    }
    [cell setNeedsDisplay];
    return cell;
}

- (void)loadProfileImage:(NSString*)url {
    BeagleManager *BG=[BeagleManager SharedInstance];
    NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
    BG.beaglePlayer.profileData=imageData;
    UIImage* image =[[UIImage alloc] initWithData:imageData];
    [self performSelectorOnMainThread:@selector(imageCircular:) withObject:image waitUntilDone:NO];
}
-(void)imageCircular:(UIImage*)image{
    UITableViewCell *cell = (UITableViewCell*)[self.settingsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    UIImageView *profileImageView=(UIImageView*)[cell viewWithTag:2345];
    profileImageView.image=[BeagleUtilities imageCircularBySize:image sqr:52.5f];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

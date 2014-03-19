//
//  ActivityViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 06/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

//36e2980516d0e60864cd29c621a09722

#import "ActivityViewController.h"
#import "TimeFilterView.h"
#import "LocationTableViewController.h"
#import "UIViewController+MJPopupViewController.h"
@interface ActivityViewController ()<UITextViewDelegate,MJSecondPopupDelegate3>{
    IBOutlet UIImageView *profileImageView;
    IBOutlet UITextView *descriptionTextView;
    UILabel *placeholderLabel;
    IBOutlet UILabel *countTextLabel;
}
@property (nonatomic, strong) NSMutableIndexSet *optionIndices;
@end

@implementation ActivityViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.optionIndices = [NSMutableIndexSet indexSetWithIndex:1];
    //self.view.backgroundColor=[UIColor redColor];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"  style: UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClicked:)];
    
    UIBarButtonItem *createItem = [[UIBarButtonItem alloc] initWithTitle:@"Create"  style: UIBarButtonItemStylePlain target:self action:@selector(createButtonClicked:)];

    
    self.navigationItem.leftBarButtonItem = cancelItem;
    self.navigationItem.rightBarButtonItem = createItem;
    self.navigationItem.rightBarButtonItem.enabled=NO;
    
    UIImage *picBoxImage=[UIImage imageNamed:@"picbox"];
    if(picBoxImage.size.height != picBoxImage.size.width)
        picBoxImage = [BeagleUtilities autoCrop:picBoxImage];
    
    // If the image needs to be compressed
    if(picBoxImage.size.height > 50 || picBoxImage.size.width > 50)
        profileImageView.image = [BeagleUtilities compressImage:picBoxImage size:CGSizeMake(50,50)];
    else
        profileImageView.image = picBoxImage;
    
    // Turning it into a round image
    profileImageView.layer.cornerRadius = picBoxImage.size.width/2;
    profileImageView.layer.masksToBounds=YES;
    
    placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(3, 0, descriptionTextView.frame.size.width - 20.0, 34.0)];
    [placeholderLabel setText:@"Tell us more..."];
    // placeholderLabel is instance variable retained by view controller
    [placeholderLabel setBackgroundColor:[UIColor clearColor]];
    placeholderLabel.font = [UIFont systemFontOfSize:14.0f];
    placeholderLabel.textColor=[UIColor lightGrayColor];
    
    // textView is UITextView object you want add placeholder text to
    [descriptionTextView addSubview:placeholderLabel];
    
    countTextLabel.text= [[NSString alloc] initWithFormat:@"%lu",(unsigned long)140-[descriptionTextView.text length]];
    [descriptionTextView becomeFirstResponder];



	// Do any additional setup after loading the view.
}
-(void)cancelButtonClicked:(id)sender{
    
    [self.navigationController dismissViewControllerAnimated:YES completion:Nil];
}
-(void)createButtonClicked:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UITexViewDelegate Methods


-(void)textViewDidChange:(UITextView *)textView{
    
    if(![textView hasText]) {
        placeholderLabel.hidden = NO;
    }
    else{
        placeholderLabel.hidden = YES;
    }
    
}

-(void)textViewDidBeginEditing:(UITextView *)textView{
    
}
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
	BOOL flag = NO;
	
	
	if ([text isEqualToString:@"\n"]){
        return NO;
	}
	
	if([text length] == 0)
	{
		if([textView.text length] != 0)
		{
			flag = YES;
			NSString *Temp = countTextLabel.text;
			int j = [Temp intValue];
            NSLog(@"j=%d",j);
            
			j = j-1 ;
			countTextLabel.text= [[NSString alloc] initWithFormat:@"%lu",141-[textView.text length]];
            
			return YES;
		}
		else {
			return NO;
		}
		
		
	}
	else if([[textView text] length] == 140)
	{
		return NO;
	}
	if(flag == NO)
	{
		countTextLabel.text= [[NSString alloc] initWithFormat:@"%lu",140-[descriptionTextView.text length]-1];
		
		
	}
	
	
	return YES;
	
	
}
-(void)textViewDidEndEditing:(UITextView *)textView{
    if (![textView hasText]) {
        placeholderLabel.hidden = NO;
    }
    
    
    
}

- (IBAction)visibilityFilter:(id)sender{
    
}

- (IBAction)locationFilter:(id)sender{
    
    [descriptionTextView resignFirstResponder];
    
    LocationTableViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"locationScreen"];
    viewController.delegate=self;
    [self presentPopupViewController:viewController animationType:MJPopupViewAnimationSlideLeftLeft];
}


- (IBAction)timeFilter:(id)sender{
    
}


- (void)cancelButtonClicked3:(LocationTableViewController*)secondDetailViewController
{
    
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationSlideLeftLeft];
    [descriptionTextView becomeFirstResponder];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}


@end

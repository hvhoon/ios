//
//  ActivityViewController.m
//  Beagle
//
//  Created by Kanav Gupta on 06/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "ActivityViewController.h"
#import "TimeFilterView.h"
#import "RNFrostedSidebar.h"
@interface ActivityViewController ()<UITextViewDelegate,RNFrostedSidebarDelegate>{
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
   // [descriptionTextView becomeFirstResponder];



	// Do any additional setup after loading the view.
}
-(void)cancelButtonClicked:(id)sender{
    
    [self onBurger];
//    [self.navigationController popViewControllerAnimated:YES];
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

-(void)test{
    CGRect blurFrame = CGRectMake(-320, 0, 320, self.view.bounds.size.height);
    
    UIView *temp=[[UIView alloc]initWithFrame:blurFrame];
    [temp setBackgroundColor:[UIColor clearColor]];
    
    UIToolbar *_nativeBlurView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.bounds.size.height)];
    _nativeBlurView.alpha=0.95f;
    [temp insertSubview:_nativeBlurView atIndex:0];
    
//    CGRect contentFrame = self.view.bounds;
    
//    int count = [[[UIApplication sharedApplication]windows]count];
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0]addSubview:temp];

    
    [UIView animateWithDuration:0.3 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut  | UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        temp.transform = CGAffineTransformMakeTranslation(320.0f, 0.0f);
        
    } completion:^(BOOL finished) {
        
        
    }];
    

    sleep(10);
    
    [UIView animateWithDuration:0.3 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
        
         temp.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
        
        
    }];

}

-(void)show{
    

    
    UIView *temp=[[UIView alloc]init];
    [temp setBackgroundColor:[UIColor clearColor]];
    
    CGRect contentFrame = self.view.bounds;
    contentFrame.origin.x = 0 ? 320 : -320;
    contentFrame.size.width = 320;
    temp.frame = contentFrame;


    CGRect blurFrame = CGRectMake(0 ? self.view.bounds.size.width : 0, 0, 0, self.view.bounds.size.height);

    UIToolbar *_nativeBlurView = [[UIToolbar alloc] initWithFrame:contentFrame];
    _nativeBlurView.alpha=0.95f;
    [temp insertSubview:_nativeBlurView atIndex:0];
    
    
    int count = [[[UIApplication sharedApplication]windows]count];
    [[[[UIApplication sharedApplication] windows] objectAtIndex:count-1]addSubview:temp];
    
    contentFrame.origin.x = 0 ? 0 : 0;
    blurFrame.origin.x = contentFrame.origin.x;
    blurFrame.size.width = 320;
    
    void (^animations)() = ^{
         temp.frame = contentFrame;
        _nativeBlurView.frame=blurFrame;
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
    };
    
    if (1) {
        [UIView animateWithDuration:0.4f
                              delay:0
                            options:kNilOptions
                         animations:animations
                         completion:completion];
    }
    else{
        animations();
        completion(YES);
    }

}

- (IBAction)onBurger{
    
    [descriptionTextView resignFirstResponder];
    NSArray *filterArray=@[[NSNumber numberWithInt:2]];
    
    //[descriptionTextView resignFirstResponder];
    //    RNFrostedSidebar *callout = [[RNFrostedSidebar alloc] initWithImages:filterArray selectedIndices:self.optionIndices borderColors:colors];
    RNFrostedSidebar *callout = [[RNFrostedSidebar alloc] initWithImages:filterArray];
    callout.delegate = self;
    //    callout.showFromRight = YES;
    [callout show];
}

#pragma mark - RNFrostedSidebarDelegate

- (void)sidebar:(RNFrostedSidebar *)sidebar didTapItemAtIndex:(NSUInteger)index {
    NSLog(@"Tapped item at index %lu",(unsigned long)index);
        [sidebar dismissAnimated:YES completion:nil];
}

- (void)sidebar:(RNFrostedSidebar *)sidebar didEnable:(BOOL)itemEnabled itemAtIndex:(NSUInteger)index {
    if (itemEnabled) {
        [self.optionIndices addIndex:index];
    }
    else {
        [self.optionIndices removeIndex:index];
    }
}


@end

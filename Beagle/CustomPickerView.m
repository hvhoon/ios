//
//  CustomPickerView.m
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "CustomPickerView.h"

@interface CustomPickerView (){
    IBOutlet UIDatePicker *pickerView;
    IBOutlet UILabel *monthYearLabel;
    NSArray *monthArray;
    NSArray *yearArray;
    NSInteger monthNow;
    NSInteger yearNow;
    NSInteger year;
    NSInteger month;
}
@end

@implementation CustomPickerView
@synthesize delegate=_delegate;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
//        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CustomPickerView" owner:self options:nil];
//        
//        UIView *view=[nib objectAtIndex:0];
//        view.frame=CGRectMake(0, 0, 320, 568);
        
//        CGSize pickerSize = [pickerView sizeThatFits:CGSizeZero];
//        
//        UIView *pickerTransformView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, pickerSize.width, pickerSize.height)];
//        pickerTransformView.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
//        
//        [pickerTransformView addSubview:pickerView];
//        [self addSubview:pickerTransformView];
        
//        [self addSubview:view];

        
//        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//        // make your gesture recognizer priority
//        singleTap.numberOfTapsRequired = 1;
//        [self addGestureRecognizer:singleTap];

       

    }
    return self;
}
-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    [_delegate filterIndex:0];
    
}

-(void)buildTheLogic{
    
    
//    CGSize pickerSize = [pickerView sizeThatFits:CGSizeZero];
//    
//    UIView *pickerTransformView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, pickerSize.width, pickerSize.height)];
//    pickerTransformView.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
//    
//    [pickerTransformView addSubview:pickerView];
//    [self addSubview:pickerTransformView];
//    
//    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
//    // make your gesture recognizer priority
//    singleTap.numberOfTapsRequired = 1;
//    [self addGestureRecognizer:singleTap];

    [ pickerView setMinimumDate:[NSDate date]];
    NSDate *today = [[NSDate alloc] init];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setYear:2];
    NSDate *nextYear = [gregorian dateByAddingComponents:offsetComponents toDate:today options:0];

    [pickerView setMaximumDate:nextYear];
    
    monthArray=[NSArray arrayWithObjects:@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August",@"September",@"October",@"November",@"December",nil];
    
    NSDate *currentDate = [NSDate date];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:currentDate]; // Get necessary date components
    
    
    [pickerView addTarget:self
                   action:@selector(dateChange:)
         forControlEvents:UIControlEventValueChanged];
    month =[components month]; //gives you month
    [components day]; //gives you day
     year =[components year]; // gives you year
    
    NSLog(@"month=%li,year=%li",month,year);

    monthNow=month;
    yearNow=year;
    yearArray=[NSArray arrayWithObjects:[NSNumber numberWithInteger:year],[NSNumber numberWithInteger:year+1],[NSNumber numberWithInteger:year+2], nil];
    
    monthYearLabel.text=[NSString stringWithFormat:@"%@ %@",[monthArray objectAtIndex:month-1],[yearArray objectAtIndex:0]];
}

-(IBAction)leftButtonClicked:(id)sender{
    if(yearNow-year==0 && month-monthNow==0){
        return;
    }
    
    
    if(monthNow==1){
        monthNow=12;
        yearNow=yearNow-1;
    }
    else{
        monthNow--;
    }

    monthYearLabel.text=[NSString stringWithFormat:@"%@ %@",[monthArray objectAtIndex:monthNow-1],[yearArray objectAtIndex:yearNow-year]];

    NSDate *currentDate = pickerView.date;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:currentDate]; // Get necessary date components
    

    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:[components day]];
    [comps setMonth:monthNow];
    [comps setYear:yearNow];
    [comps setHour:[components hour]];
    [comps setMinute:[components minute]];
    [comps setSecond:[components second]];

    [pickerView setDate:[[NSCalendar currentCalendar] dateFromComponents:comps] animated:YES];
    

}

-(IBAction)rightButtonClicked:(id)sender{
    
    if(yearNow-year==2 && month-monthNow==0){
        return;
    }
    if(monthNow==12){
        monthNow=1;
        yearNow=yearNow+1;
    }
    else
     monthNow++;
    monthYearLabel.text=[NSString stringWithFormat:@"%@ %@",[monthArray objectAtIndex:monthNow-1],[yearArray objectAtIndex:yearNow-year]];
    
    NSDate *currentDate = pickerView.date;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:currentDate]; // Get necessary date components
    
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:[components day]];
    [comps setMonth:monthNow];
    [comps setYear:yearNow];
    [comps setHour:[components hour]];
    [comps setMinute:[components minute]];
    [comps setSecond:[components second]];

    [pickerView setDate:[[NSCalendar currentCalendar] dateFromComponents:comps] animated:YES];



}
-(void)dateChange:(id)sender{
    
    NSDate *currentDate = pickerView.date;
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:currentDate]; // Get necessary date components
    
    monthNow =[components month]; //gives you month
    yearNow =[components year]; // gives you year
    
    monthYearLabel.text=[NSString stringWithFormat:@"%@ %li",[monthArray objectAtIndex:monthNow-1],yearNow];
    





}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

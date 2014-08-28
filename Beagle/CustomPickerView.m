//
//  CustomPickerView.m
//  Beagle
//
//  Created by Kanav Gupta on 10/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import "CustomPickerView.h"
#import "UILabel+WhiteUIDatePickerLabels.h"
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
@property(nonatomic,strong)NSDate *lastPickDate;
@end

@implementation CustomPickerView
@synthesize delegate=_delegate;
@synthesize lastPickDate;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
 }
    return self;
}
-(void)handleSingleTap:(UITapGestureRecognizer*)sender{
    
        if (self.delegate && [self.delegate respondsToSelector:@selector(filterIndex:)])
                [_delegate filterIndex:0];
    
}

-(void)buildTheLogic{
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    // make your gesture recognizer priority
    singleTap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:singleTap];

    NSDateComponents *time = [[NSCalendar currentCalendar]
                              components:NSHourCalendarUnit | NSMinuteCalendarUnit
                              fromDate:[NSDate date]];
    
    NSInteger minutes = [time minute];
    int remain = minutes % 5;
    [ pickerView setMinimumDate:[[NSDate date] dateByAddingTimeInterval:60*(5-remain)]];
    lastPickDate=pickerView.date;
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
    
    pickerView.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    [pickerView addTarget:self
                   action:@selector(dateChange:)
         forControlEvents:UIControlEventValueChanged];
    month =[components month]; //gives you month
    [components day]; //gives you day
     year =[components year]; // gives you year
    
    NSLog(@"month=%li,year=%li",(long)month,(long)year);
    pickerView.minuteInterval=5.0f;
    monthNow=month;
    yearNow=year;
    yearArray=[NSArray arrayWithObjects:[NSNumber numberWithInteger:year],[NSNumber numberWithInteger:year+1],[NSNumber numberWithInteger:year+2], nil];
    
    monthYearLabel.text=[NSString stringWithFormat:@"%@ %@",[monthArray objectAtIndex:month-1],[yearArray objectAtIndex:0]];
}


-(void)updateTheDateInEditMode{
    NSDateComponents *time = [[NSCalendar currentCalendar]
                              components:NSHourCalendarUnit | NSMinuteCalendarUnit
                              fromDate:[NSDate date]];
    
    NSInteger minutes = [time minute];
    int remain = minutes % 5;
    [ pickerView setMinimumDate:[[NSDate date] dateByAddingTimeInterval:60*(5-remain)]];

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
    [comps setHour:9];
    [comps setMinute:0];
    [comps setSecond:0];

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
    [comps setHour:9];
    [comps setMinute:0];
    [comps setSecond:0];

    [pickerView setDate:[[NSCalendar currentCalendar] dateFromComponents:comps] animated:YES];



}
-(IBAction)scrollToTheTopSelected:(id)sender{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideUpToSelectTime)])
           [_delegate slideUpToSelectTime];

}
-(void)dateChange:(id)sender{
    
    [self updateTheDateInEditMode];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:pickerView.date]; // Get necessary date components
    
    monthNow =[components month]; //gives you month
    yearNow =[components year]; // gives you year
    
    monthYearLabel.text=[NSString stringWithFormat:@"%@ %li",[monthArray objectAtIndex:monthNow-1],(long)yearNow];
    
    NSDateComponents*lastDatecomponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:lastPickDate]; // Get necessary date components
    
    
    if(([lastDatecomponents day]-[components day])!=0){
        [components setHour:9];
        [components setMinute:0];
        [components setSecond:0];

        [pickerView setDate:[[NSCalendar currentCalendar] dateFromComponents:components] animated:YES];
    }
    
    
    lastPickDate = pickerView.date;

}
-(IBAction)pickDateSelected:(id)sender{
    if (self.delegate && [self.delegate respondsToSelector:@selector(datePicked:)])
            [_delegate datePicked:pickerView.date];
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

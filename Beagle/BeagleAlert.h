//
//  BeagleAlert.h
//  Beagle
//
//  Created by Kanav Gupta on 04/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <UIKit/UIKit.h>


void BeagleAlertWithError(NSError *error);
void BeagleAlertWithMessage(NSString *message);
void BeagleAlertWithMessageAndDelegate(NSString *message, id delegate);

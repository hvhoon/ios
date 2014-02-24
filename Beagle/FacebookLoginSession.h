//
//  FacebookLoginSession.h
//  Beagle
//
//  Created by Kanav Gupta on 24/02/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/ACAccountStore.h>
#import <Accounts/ACAccount.h>
@class BeagleUserClass;
@protocol FacebookLoginSessionDelegate <NSObject>

@optional
-(void)successfulFacebookLogin:(BeagleUserClass*)data;
-(void)facebookAccountNotSetup;
@end


@interface FacebookLoginSession : NSObject{
    id <FacebookLoginSessionDelegate>delegate;
    NSDictionary *list;
}

@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccount *facebookAccount;
@property(nonatomic,strong)id<FacebookLoginSessionDelegate>delegate;
-(void)getUserNativeFacebookSession;
-(void)get;
@end

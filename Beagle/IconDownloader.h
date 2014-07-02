
//
//  IconDownloader.h
//  Beagle
//
//  Created by Kanav Gupta on 25/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

@class BeagleActivityClass;
@class InterestChatClass;
@class BeagleNotificationClass;
@class BeagleUserClass;
@protocol IconDownloaderDelegate;

@interface IconDownloader : NSObject
{
    BeagleActivityClass *appRecord;
    InterestChatClass *chatRecord;
    BeagleNotificationClass *notificationRecord;
    NSIndexPath *indexPathInTableView;
    NSMutableData *activeDownload;
    NSURLConnection *imageConnection;
    NSInteger tagkey;
    BeagleUserClass *friendRecord;
    
}
@property (nonatomic, strong) BeagleNotificationClass *notificationRecord;
@property (nonatomic, strong) InterestChatClass *chatRecord;
@property (nonatomic, strong) BeagleActivityClass *appRecord;
@property (nonatomic, strong) NSIndexPath *indexPathInTableView;
@property (nonatomic, assign) id <IconDownloaderDelegate> delegate;
@property (nonatomic,assign)NSInteger tagkey;
@property (nonatomic, strong) NSMutableData *activeDownload;
@property (nonatomic, strong) NSURLConnection *imageConnection;
@property(nonatomic,strong)BeagleUserClass*friendRecord;
- (void)startDownload:(NSInteger)uniqueKey;
- (void)cancelDownload;

@end

@protocol IconDownloaderDelegate <NSObject>

- (void)appImageDidLoad:(NSIndexPath *)indexPath;
@end
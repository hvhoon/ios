
//
//  IconDownloader.h
//  Beagle
//
//  Created by Kanav Gupta on 25/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

@class BeagleActivityClass;
@class InterestChatClass;
@protocol IconDownloaderDelegate;

@interface IconDownloader : NSObject
{
    BeagleActivityClass *appRecord;
    InterestChatClass *chatRecord;
    NSIndexPath *indexPathInTableView;
    NSMutableData *activeDownload;
    NSURLConnection *imageConnection;
    NSInteger tagkey;
    
}
@property (nonatomic, strong) InterestChatClass *chatRecord;
@property (nonatomic, strong) BeagleActivityClass *appRecord;
@property (nonatomic, strong) NSIndexPath *indexPathInTableView;
@property (nonatomic, assign) id <IconDownloaderDelegate> delegate;
@property (nonatomic,assign)NSInteger tagkey;
@property (nonatomic, strong) NSMutableData *activeDownload;
@property (nonatomic, strong) NSURLConnection *imageConnection;

- (void)startDownload:(NSInteger)uniqueKey;
- (void)cancelDownload;

@end

@protocol IconDownloaderDelegate 

- (void)appImageDidLoad:(NSIndexPath *)indexPath;
@end
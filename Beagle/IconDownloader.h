
//
//  IconDownloader.h
//  Beagle
//
//  Created by Kanav Gupta on 25/03/14.
//  Copyright (c) 2014 soclivity. All rights reserved.
//

@class BeagleActivityClass;
@protocol IconDownloaderDelegate;

@interface IconDownloader : NSObject
{
    BeagleActivityClass *appRecord;
    NSIndexPath *indexPathInTableView;
    NSMutableData *activeDownload;
    NSURLConnection *imageConnection;
    NSInteger tagkey;
    
}
@property (nonatomic, retain) BeagleActivityClass *appRecord;
@property (nonatomic, retain) NSIndexPath *indexPathInTableView;
@property (nonatomic, assign) id <IconDownloaderDelegate> delegate;
@property (nonatomic,assign)NSInteger tagkey;
@property (nonatomic, retain) NSMutableData *activeDownload;
@property (nonatomic, retain) NSURLConnection *imageConnection;

- (void)startDownload:(NSInteger)uniqueKey;
- (void)cancelDownload;

@end

@protocol IconDownloaderDelegate 

- (void)appImageDidLoad:(NSIndexPath *)indexPath;
@end
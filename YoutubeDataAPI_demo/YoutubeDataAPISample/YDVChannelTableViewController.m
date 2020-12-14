//
//  YDVChannelTableViewController.m
//  YoutubeDataAPISample
//
//  Created by Abhijeet Mishra on 13/02/18.
//  Copyright © 2018 Abhijeet Mishra. All rights reserved.
//

#import "YDVChannelTableViewController.h"
#import <PrimeData.h>


@interface YDVChannelTableViewController ()

@property (nonatomic) NSArray* videoList;

@end

@implementation YDVChannelTableViewController

- (void) viewDidLoad {
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    self.tableView.rowHeight = 180;
    self.title = @"POPS Anime Videos";
}


- (void) viewDidAppear:(BOOL)animated {
    [self getVideoList];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.videoList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YDVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([YDVideoTableViewCell class]) forIndexPath:indexPath];
    [cell.playerView loadWithVideoId:self.videoList[indexPath.row]];
    cell.playerView.delegate = self;
    return cell;
}

#pragma mark - API Methods

- (void)playerView:(nonnull YTPlayerView *)playerView didChangeToState:(YTPlayerState)state
{
    NSLog(@"%d", state);
    __block NSString *duaration = [playerView getDuration];
    __block NSString *url = [playerView getVideoUrl];
    __block NSString *videoId = playerView.videoId;
    if (state == kYTPlayerStatePlaying)
    {
        [self getVideoInfo:playerView.videoId retBlock:^(NSDictionary *dic) {
           
            [[PDAnalytics sharedAnalytics] track:@"play"
                                      properties: @{
                                                  }
                                          source:@{
                                                      @"itemId": @"pops.anime",
                                                      @"itemType": @"app"
                                                  }
                                          target: @{
                                              @"itemId": videoId,
                                                       @"itemType": @"video",
                                                       @"properties": @{
                                                         @"duration" : duaration,
                                                         @"url" : url,
                                                         @"category":  [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"categoryId"],
                                                         @"channel": [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"channelTitle"],
                                                         @"title": [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"title"],
                                                         @"type": [[dic objectForKey:@"items"][0] objectForKey:@"kind"]
                                                       }
                                                   }];
            
        }];
    }
    if (state == kYTPlayerStatePaused)
    {
        [self getVideoInfo:playerView.videoId retBlock:^(NSDictionary *dic) {
           
            [[PDAnalytics sharedAnalytics] track:@"pause"
                                      properties: @{
                                                  }
                                          source:@{
                                                      @"itemId": @"pops.anime",
                                                      @"itemType": @"app"
                                                  }
                                          target: @{
                                              @"itemId": videoId,
                                                       @"itemType": @"video",
                                                       @"properties": @{
                                                         @"duration" : duaration,
                                                         @"url" : url,
                                                         @"category":  [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"categoryId"],
                                                         @"channel": [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"channelTitle"],
                                                         @"title": [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"title"],
                                                         @"type": [[dic objectForKey:@"items"][0] objectForKey:@"kind"]
                                                       }
                                                   }];
            
        }];
    }
    
    if (state == kYTPlayerStateEnded)
    {
        [self getVideoInfo:playerView.videoId retBlock:^(NSDictionary *dic) {
           
            [[PDAnalytics sharedAnalytics] track:@"ended"
                                      properties: @{
                                                  }
                                          source:@{
                                                      @"itemId": @"pops.anime",
                                                      @"itemType": @"app"
                                                  }
                                          target: @{
                                              @"itemId": videoId,
                                                       @"itemType": @"video",
                                                       @"properties": @{
                                                         @"duration" : duaration,
                                                         @"url" : url,
                                                         @"category":  [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"categoryId"],
                                                         @"channel": [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"channelTitle"],
                                                         @"title": [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"title"],
                                                         @"type": [[dic objectForKey:@"items"][0] objectForKey:@"kind"]
                                                       }
                                                   }];
            
        }];
    }
    
    if (state == kYTPlayerStateBuffering)
    {
        [self getVideoInfo:playerView.videoId retBlock:^(NSDictionary *dic) {
           
            [[PDAnalytics sharedAnalytics] track:@"seek"
                                      properties: @{
                                                  }
                                          source:@{
                                                      @"itemId": @"pops.anime",
                                                      @"itemType": @"app"
                                                  }
                                          target: @{
                                              @"itemId": videoId,
                                                       @"itemType": @"video",
                                                       @"properties": @{
                                                         @"duration" : duaration,
                                                         @"url" : url,
                                                         @"category":  [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"categoryId"],
                                                         @"channel": [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"channelTitle"],
                                                         @"title": [[[dic objectForKey:@"items"][0] objectForKey:@"snippet"] objectForKey:@"title"],
                                                         @"type": [[dic objectForKey:@"items"][0] objectForKey:@"kind"]
                                                       }
                                                   }];
            
        }];
    }
}

- (void) getVideoInfo:(NSString*)videId retBlock: (void (^)(NSDictionary *dic))completionHandler {
    
    //firebase channel being used
    NSString* urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/videos?part=snippet&id=%@&key=AIzaSyAnfEMEP1NtYc4bmXLRrlRJwgJQ1SATFQY", videId];
    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString:urlString]];
    [request setHTTPMethod:@"GET"];

    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            completionHandler(responseDict);
        }
    }];
    [dataTask resume];
}

- (void) getVideoList {
    
    //firebase channel being used
    NSString* urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?channelId=UCkgdDBHO7zl3tWIjldQeK7g&access_token=%@&part=snippet&maxResults=10",[[NSUserDefaults standardUserDefaults] valueForKey:@"token"]];
    NSLog(@"access token: %@", [[NSUserDefaults standardUserDefaults] valueForKey:@"token"]);
    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    
 //   NSString* token = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            self.videoList = @[];
            
            NSMutableArray* newVideoList = [@[] mutableCopy];
            
            NSArray* videoItems = responseDict[@"items"];
            
            for (NSDictionary* videoDict in videoItems) {
                NSString* videoID = videoDict[@"id"][@"videoId"];
                [newVideoList addObject:videoID];
            }
            self.videoList = [newVideoList copy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    }];
    [dataTask resume];
}

@end

//
//  YDVideoTableViewCell.h
//  YoutubeDataAPISample
//
//  Created by Abhijeet Mishra on 13/02/18.
//  Copyright © 2018 Abhijeet Mishra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTPlayerView.h"

@interface YDVideoTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet YTPlayerView *playerView;

@end

//
//  ViewController.m
//  YoutubeDataAPISample
//
//  Created by Abhijeet Mishra on 11/02/18.
//  Copyright © 2018 Abhijeet Mishra. All rights reserved.
//

#import "ViewController.h"

@import GoogleSignIn;

@interface ViewController () <GIDSignInUIDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [GIDSignIn sharedInstance].uiDelegate = self;
    self.title = @"Login";

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogIn) name:@"userLoggedIn" object:nil];
}

- (void) userDidLogIn {
    [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"YDVChannelTableViewController"] animated:YES];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

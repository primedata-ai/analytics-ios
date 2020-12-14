//
//  YDUploadViewController.m
//  YoutubeDataAPISample
//
//  Created by Abhijeet Mishra on 12/02/18.
//  Copyright © 2018 Abhijeet Mishra. All rights reserved.
//

#import "YDUploadViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface YDUploadViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) NSURL* videoURL;

@end

@implementation YDUploadViewController

- (void) viewDidLoad {
    self.title = @"Choose Video";
}

- (IBAction)chooseVideoClicked:(UIButton *)sender {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Record a Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showRecordVideo];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Choose a Video" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showChooseVideo];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void) showRecordVideo {
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    picker.allowsEditing = NO;
    
    NSArray *mediaTypes = [[NSArray alloc]initWithObjects:(NSString *)kUTTypeMovie, nil];
    
    picker.mediaTypes = mediaTypes;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void) showChooseVideo {
    // Present videos from which to choose
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.delegate = self; // ensure you set the delegate so when a video is chosen the right method can be called
    
    videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    // This code ensures only videos are shown to the end user
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:videoPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // This is the NSURL of the video object
    self.videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    
    NSLog(@"VideoURL = %@", self.videoURL);
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    self.title = @"Uploading Video...";
    
    [self uploadVideo];
}

- (void) uploadVideo {
    
    NSData* videoData = [[NSFileManager defaultManager] contentsAtPath:self.videoURL.path];
    
    NSString* urlString = [NSString stringWithFormat:@"https://www.googleapis.com/upload/youtube/v3/videos?part=snippet,status,contentDetails&access_token=%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"token"]];
    
    NSURLSessionConfiguration* sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[[NSURL alloc] initWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    NSString* token = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
    
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    [request setValue:[@(videoData.length) stringValue] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"video/*, application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[@(videoData.length) stringValue] forHTTPHeaderField:@"X-Upload-Content-Length"];
    [request setValue:@"video/*" forHTTPHeaderField:@"x-upload-content-type"];
    
    NSMutableDictionary* bodyDict = [@{} mutableCopy];
    
    NSMutableDictionary* snippetDict = [@{} mutableCopy];
    [snippetDict setValue:@"test" forKey:@"title"];
    [snippetDict setValue:@[@"cool",@"video",@"more keywords"] forKey:@"tags"];
    [snippetDict setValue:@(22) forKey:@"categoryId"];
    
    NSMutableDictionary* statusDict = [@{} mutableCopy];
    [statusDict setValue:@"public" forKey:@"privacyStatus"];
    [statusDict setValue:@true forKey:@"embeddable"];
    [statusDict setValue:@"youtube" forKey:@"license"];
    
    [bodyDict setValue:snippetDict forKey:@"snippet"];
    [bodyDict setValue:statusDict forKey:@"status"];
    request.HTTPBody = videoData;
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            NSString* responseString = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            
            NSLog(@"response received: %@",responseString);
            
            UIAlertController* alertView = [UIAlertController alertControllerWithTitle:nil message:@"Video Uploaded!" preferredStyle:UIAlertControllerStyleAlert];
            [alertView addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }]];
            [self presentViewController:alertView animated:YES completion:nil];
        }
    }];
    [dataTask resume];
}

@end

# YoutubeDataAPI
Sample iOS app implementing the Youtube Data API v3 video insert + search list functionality


## Motivation
Have ever tried developing an iOS application performing simple channel listing + video upload functionality on Youtube. Not sure about you, but I had a terrible time exploring various links like 
- [Youtube iOS Documentation](https://developers.google.com/youtube/v3/quickstart/ios)
- [Stackoverflow](https://stackoverflow.com/questions/42002514/video-upload-to-youtube-from-app)
- [Google project on Github](https://github.com/google/google-api-objectivec-client) 

:unamused::tired_face::expressionless:


In the end managed to implement it using the [Youtube Data API Web service documentation](https://developers.google.com/youtube/v3/docs/) and [Google OAuth flow for iOS](https://developers.google.com/identity/sign-in/ios/start-integrating). 

Its just a basic project with barebone working UI but can serve as a template for other applications trying to expand on these basic functionalities.


## Installation

1. Download the reference code and edit the bundle ID to enter that of your own.
![alt text](https://user-images.githubusercontent.com/17490066/36351878-fa93514c-14d5-11e8-9ee0-0100a8010e4b.png)


2. Follow the steps mentioned here to create a [Google OAuth Client ID](https://developers.google.com/identity/sign-in/ios/start-integrating). Copy the client ID and reversed client ID obtained in the end, these will be needed.
3. Open AppDelegate.m , inside method mentioned below enter the google client ID created above in Step 2.
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [GIDSignIn sharedInstance].clientID = @"<Your Client ID>";
    [GIDSignIn sharedInstance].scopes = [[GIDSignIn sharedInstance].scopes arrayByAddingObject:@"https://www.googleapis.com/auth/youtube"];
    [GIDSignIn sharedInstance].delegate = self;

    return YES;
}
```
4. Click the YoutubeDataAPI target in your project navigator --> Click on Info tab --> Go to the URL Types section --> Add a new section if a blank one is not present --> Add the reveresed client ID obtained in Step 2 to the URL Schemes section.
5. Make sure Youtube Data v3 API is enabled in your developer console [Youtube Data v3 API Google Developer Console](https://console.cloud.google.com/apis/library/youtube.googleapis.com/)

That's it! Should work with a breeze :trollface: :see_no_evil:

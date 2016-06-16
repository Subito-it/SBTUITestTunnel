// SBTViewController.m
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "SBTViewController.h"
#import "SBTUITestTunnelServer.h"

@interface SBTViewController ()
@property (nonatomic, strong) UIAlertController *alert;
@end

@implementation SBTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.alert = [UIAlertController alertControllerWithTitle:@"Result" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [self.alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommand" block:^(NSObject *object) {
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:@"custom_command_test"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
}

- (IBAction)doGoogleNetRequestTapped:(id)sender
{
    [self requestURLAndShowAlertView:@"https://www.google.com/?q=tennis"];
}

- (IBAction)doYahooNetRequestTapped:(id)sender
{
    [self requestURLAndShowAlertView:@"https://us.yahoo.com/?p=us&l=1"];
}

- (IBAction)doDuckNetRequestTapped:(id)sender
{
    [self requestURLAndShowAlertView:@"http://duckduckgo.com/?q=tennis"];
}

- (void)requestURLAndShowAlertView:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block NSData *responseData = nil;
    
    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        responseData = data;
        dispatch_semaphore_signal(sem);
    }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    id object = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
    
    if ([object[@"request"] isEqualToString:@"stubbed"])  {
        self.alert.message = @"Stubbed";
    } else {
        self.alert.message = @"Not Stubbed";
    }
    
    [self presentViewController:self.alert animated:YES completion:nil];
    
}

@end

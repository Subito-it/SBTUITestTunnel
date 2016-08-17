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
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (nonatomic, strong) UIAlertController *alert;
@end

@implementation SBTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.alert = [UIAlertController alertControllerWithTitle:@"Result" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [self.alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommandReturnNil" block:^NSObject *(NSObject *object) {
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:@"custom_command_test"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        return nil;
    }];
    [SBTUITestTunnelServer registerCustomCommandNamed:@"myCustomCommandReturn123" block:^NSObject *(NSObject *object) {
        [[NSUserDefaults standardUserDefaults] setObject:object forKey:@"custom_command_test"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        return @"123";
    }];
}

- (IBAction)doBingRequestTapped:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
        NSURL *url = [NSURL URLWithString:@"https://www.bing.com/?q=retdata"];
        
        __block NSData *responseData = nil;    
    
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            responseData = data;
            dispatch_semaphore_signal(sem);
        }] resume];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            self.resultLabel.text = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
        });
    });
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
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
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self presentViewController:self.alert animated:YES completion:nil];
        });
    });
}

- (IBAction)delayedBingRequestTapped:(id)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:@"https://www.bing.com/?q=retdata"];
        
        __block NSData *responseData = nil;
        
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            responseData = data;
        }] resume];
    });
}

- (IBAction)doPostRequest:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        NSURL *url = [NSURL URLWithString:@"http://httpbin.org/post"];
        
        __block NSData *responseData = nil;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        request.HTTPMethod = @"POST";
        
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"k1": @"v1", @"k2": @"v2", @"k3": @"v3" }
                                                       options:kNilOptions error:&error];

        [[[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
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
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self presentViewController:self.alert animated:YES completion:nil];
        });
    });
}

- (IBAction)doPutRequest:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        
        NSURL *url = [NSURL URLWithString:@"http://httpbin.org/put"];
        
        __block NSData *responseData = nil;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        request.HTTPMethod = @"PUT";
        
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:@{@"k1": @"v1", @"k2": @"v2", @"k3": @"v3" }
                                                       options:kNilOptions error:&error];
        
        [[[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
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
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self presentViewController:self.alert animated:YES completion:nil];
        });
    });
}

@end

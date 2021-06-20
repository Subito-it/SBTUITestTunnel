//  UIViewController+SBTUITestTunnel.m
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

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

@import SBTUITestTunnelCommon;

#import "UIViewController+SBTUITestTunnel.h"

@interface SBTUIViewControllerPreviewingGroup : NSObject

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) id<UIViewControllerPreviewingDelegate> delegate;

@end

@implementation UIViewController (SBTUITestTunnel)

static NSMapTable<UIView *, id<UIViewControllerPreviewingDelegate>> *previewingDelegates;

+ (UIView *)previewingRegisteredViewForView:(UIView *)view;
{
    for (UIView *registeredView in previewingDelegates.keyEnumerator) {
        if ([view isDescendantOfView:registeredView]) {
            return registeredView;
        }
    }
    
    return nil;
}

+ (id<UIViewControllerPreviewingDelegate>)previewingDelegateForRegisteredView:(UIView *)view
{
    return [previewingDelegates objectForKey:view];
}

- (id<UIViewControllerPreviewing>)swz_registerForPreviewingWithDelegate:(id<UIViewControllerPreviewingDelegate>)delegate sourceView:(UIView *)sourceView;
{
    id<UIViewControllerPreviewing> ret = [self swz_registerForPreviewingWithDelegate:delegate sourceView:sourceView];
    
    if (previewingDelegates == nil) {
        previewingDelegates = [NSMapTable weakToWeakObjectsMapTable];
    }
    
    [previewingDelegates setObject:delegate forKey:sourceView];
    
    return ret;
}

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SBTTestTunnelInstanceSwizzle(self, @selector(registerForPreviewingWithDelegate:sourceView:), @selector(swz_registerForPreviewingWithDelegate:sourceView:));
    });
}

@end

#endif

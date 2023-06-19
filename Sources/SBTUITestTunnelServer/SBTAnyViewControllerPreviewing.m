//  SBTAnyViewControllerPreviewing
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

#import "include/SBTAnyViewControllerPreviewing.h"

@interface SBTAnyViewControllerPreviewing()

@property (nonatomic, weak) id<UIViewControllerPreviewingDelegate> previewingDelegate;
@property (nonatomic, weak) UIView *previewingSourceView;

@end

@implementation SBTAnyViewControllerPreviewing

- (instancetype)initWithSourceView:(UIView *)view delegate:(id<UIViewControllerPreviewingDelegate>)delegate
{
    if (self = [super init]) {
        self.previewingDelegate = delegate;
        self.previewingSourceView = view;
    }

    return self;
}

- (UIGestureRecognizer *)previewingGestureRecognizerForFailureRelationship
{
    return [[UIGestureRecognizer alloc] init];
}

- (id<UIViewControllerPreviewingDelegate>)delegate
{
    return self.previewingDelegate;
}

- (UIView *)sourceView
{
    return self.previewingSourceView;
}

- (CGRect)sourceRect
{
    return self.previewingSourceView.bounds;
}

@end

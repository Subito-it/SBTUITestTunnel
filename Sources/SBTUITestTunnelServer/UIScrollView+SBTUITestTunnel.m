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

@import SBTUITestTunnelCommon;

#import "UIScrollView+SBTUITestTunnel.h"

@implementation UIScrollView (SBTUITestTunnel)

- (BOOL)shouldScrollVertically {
    return self.frame.size.width >= self.contentSize.width && self.frame.size.height < self.contentSize.height;
}

- (BOOL)shouldScrollHorizontally {
    return self.frame.size.height >= self.contentSize.height && self.frame.size.width < self.contentSize.width;
}

- (SBTUITestTunnelScrollDirection)suggestedScrollDirection {
    if (self.shouldScrollVertically) {
        return SBTUITestTunnelScrollDirectionVertical;
    } else if (self.shouldScrollHorizontally) {
        return SBTUITestTunnelScrollDirectionHorizontal;
    }

    // In case no scroll direction can be guessed we give higher priority to vertical scroll, since it's the most common one
    return SBTUITestTunnelScrollDirectionVertical;
}

- (UICollectionViewScrollPosition)suggestedScrollPosition {
    if (self.suggestedScrollDirection == SBTUITestTunnelScrollDirectionVertical) {
        return UICollectionViewScrollPositionTop;
    } else if (self.suggestedScrollDirection == SBTUITestTunnelScrollDirectionHorizontal) {
        return UICollectionViewScrollPositionLeft;
    }

    // In case no scroll direction can be guessed we give higher priority to vertical scroll, since it's the most common one
    return UICollectionViewScrollPositionTop;
}

@end

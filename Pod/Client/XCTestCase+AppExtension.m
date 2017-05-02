// XCTestCase+AppExtension.m
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

#import "XCTestCase+AppExtension.h"
#import "SBTSwizzleHelpers.h"

@implementation XCTestCase (AppExtension)

static char kAppAssociatedKey;

- (void)setApp:(SBTUITunneledApplication *)app
{
    return objc_setAssociatedObject(self, &kAppAssociatedKey, app, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SBTUITunneledApplication *)app
{
    SBTUITunneledApplication *ret = objc_getAssociatedObject(self, &kAppAssociatedKey);
    if (!ret) {
        ret = [[SBTUITunneledApplication alloc] init];
        objc_setAssociatedObject(self, &kAppAssociatedKey, ret, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ret;
}

@end

#endif

// SBTSwizzleHelpers.h
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

#import <objc/runtime.h>

__unused static void SBTTestTunnelClassSwizzle(Class cls, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getClassMethod(cls, originalSelector);
    Method swizzledMethod = class_getClassMethod(cls, swizzledSelector);
    
    if (class_addMethod(object_getClass(cls), originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(object_getClass(cls), swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

__unused static void SBTTestTunnelInstanceSwizzle(Class cls, SEL originalSelector, SEL swizzledSelector)
{
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    if (class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(cls, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

// Permanent hooks use a runtime-only alias for the original implementation.
// Do not implement originalAliasSelector in a category: another binary image
// could replace that method when loaded, breaking an already installed hook.
// Adding the alias also guards installation across copies of the library.
__unused static void SBTTestTunnelInstanceSwizzleOnce(Class cls, SEL originalSelector, SEL swizzledSelector, SEL originalAliasSelector)
{
    @synchronized (cls) {
        Method originalMethod = class_getInstanceMethod(cls, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);

        if (originalMethod && swizzledMethod &&
            class_addMethod(cls, originalAliasSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))) {
            class_replaceMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        }
    }
}

__unused static void SBTTestTunnelClassSwizzleOnce(Class cls, SEL originalSelector, SEL swizzledSelector, SEL originalAliasSelector)
{
    SBTTestTunnelInstanceSwizzleOnce(object_getClass(cls), originalSelector, swizzledSelector, originalAliasSelector);
}

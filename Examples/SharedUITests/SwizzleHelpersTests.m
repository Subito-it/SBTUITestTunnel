// SwizzleHelpersTests.m
//
// Copyright (C) 2026 Subito.it S.r.l (www.subito.it)
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

#import <XCTest/XCTest.h>
#import <objc/message.h>
@import SBTUITestTunnelCommon;

static NSInteger SBTTestOriginalValue(id self, SEL selector) { return 42; }
static NSInteger SBTTestPermanentWrapper(id self, SEL selector)
{
    return ((NSInteger (*)(id, SEL))objc_msgSend)(self, sel_registerName("sbt_testOriginalValue")) + 1;
}
static NSInteger SBTTestSecondWrapper(id self, SEL selector)
{
    return ((NSInteger (*)(id, SEL))objc_msgSend)(self, sel_registerName("sbt_testOriginalValue")) + 2;
}
static NSInteger SBTTestExchangeWrapper(id self, SEL selector)
{
    return ((NSInteger (*)(id, SEL))objc_msgSend)(self, sel_registerName("sbt_testWrapper")) + 1;
}

@interface SwizzleHelpersTests : XCTestCase
@end

@implementation SwizzleHelpersTests

- (Class)childWithInheritedMethod:(BOOL)classMethod wrapper:(IMP)wrapper
{
    NSString *suffix = [NSUUID.UUID.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    Class parent = objc_allocateClassPair(NSObject.class, [[@"SBTSwizzleParent" stringByAppendingString:suffix] UTF8String], 0);
    class_addMethod(classMethod ? object_getClass(parent) : parent, sel_registerName("sbt_testValue"), (IMP)SBTTestOriginalValue, "q@:");
    objc_registerClassPair(parent);
    Class child = objc_allocateClassPair(parent, [[@"SBTSwizzleChild" stringByAppendingString:suffix] UTF8String], 0);
    class_addMethod(classMethod ? object_getClass(child) : child, sel_registerName("sbt_testWrapper"), wrapper, "q@:");
    objc_registerClassPair(child);
    return child;
}

- (NSInteger)valueForReceiver:(id)receiver
{
    return ((NSInteger (*)(id, SEL))objc_msgSend)(receiver, sel_registerName("sbt_testValue"));
}

- (void)testInheritedClassMethodExchangePreservesOriginalAndSuperclass
{
    Class child = [self childWithInheritedMethod:YES wrapper:(IMP)SBTTestExchangeWrapper];
    SEL original = sel_registerName("sbt_testValue"), wrapper = sel_registerName("sbt_testWrapper");
    SBTTestTunnelClassSwizzle(child, original, wrapper);
    IMP alias = method_getImplementation(class_getClassMethod(child, wrapper));
    XCTAssertEqual(alias, (IMP)SBTTestOriginalValue);
    // A wrong alias would recurse indefinitely; inspect it before invoking.
    if (alias != (IMP)SBTTestOriginalValue) { return; }
    XCTAssertEqual([self valueForReceiver:child], 43);
    XCTAssertEqual([self valueForReceiver:class_getSuperclass(child)], 42);
    SBTTestTunnelClassSwizzle(child, original, wrapper);
    XCTAssertEqual([self valueForReceiver:child], 42);
}

- (void)testInheritedInstanceMethodExchangePreservesOriginalAndSuperclass
{
    Class child = [self childWithInheritedMethod:NO wrapper:(IMP)SBTTestExchangeWrapper];
    SEL original = sel_registerName("sbt_testValue"), wrapper = sel_registerName("sbt_testWrapper");
    SBTTestTunnelInstanceSwizzle(child, original, wrapper);
    XCTAssertEqual([self valueForReceiver:[child new]], 43);
    XCTAssertEqual([self valueForReceiver:[class_getSuperclass(child) new]], 42);
    SBTTestTunnelInstanceSwizzle(child, original, wrapper);
    XCTAssertEqual([self valueForReceiver:[child new]], 42);
}

- (void)checkPermanentHook:(BOOL)classMethod replaceCategory:(BOOL)replaceCategory
{
    Class child = [self childWithInheritedMethod:classMethod wrapper:(IMP)SBTTestPermanentWrapper];
    Class target = classMethod ? object_getClass(child) : child;
    SEL original = sel_registerName("sbt_testValue"), wrapper = sel_registerName("sbt_testWrapper"), alias = sel_registerName("sbt_testOriginalValue");
    void (^install)(void) = ^{
        if (classMethod) {
            SBTTestTunnelClassSwizzleOnce(child, original, wrapper, alias);
        } else {
            SBTTestTunnelInstanceSwizzleOnce(child, original, wrapper, alias);
        }
    };

    // Concurrent callers must install one hook, even without a shared once token.
    dispatch_apply(32, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t index) { install(); });
    if (replaceCategory) {
        // A second image replaces compiled category methods, but cannot replace
        // the runtime-only alias holding the original implementation.
        method_setImplementation(class_getInstanceMethod(target, wrapper), (IMP)SBTTestSecondWrapper);
    }
    install();
    IMP savedOriginal = method_getImplementation(class_getInstanceMethod(target, alias));
    XCTAssertEqual(savedOriginal, (IMP)SBTTestOriginalValue);
    if (savedOriginal != (IMP)SBTTestOriginalValue) { return; }
    XCTAssertEqual([self valueForReceiver:classMethod ? child : [child new]], 43);
    Class parent = class_getSuperclass(child);
    XCTAssertEqual([self valueForReceiver:classMethod ? parent : [parent new]], 42);
}

- (void)testPermanentClassHookInstallsOnce { [self checkPermanentHook:YES replaceCategory:NO]; }
- (void)testPermanentInstanceHookInstallsOnce { [self checkPermanentHook:NO replaceCategory:NO]; }
- (void)testPermanentClassHookSurvivesCategoryReplacement { [self checkPermanentHook:YES replaceCategory:YES]; }
- (void)testPermanentInstanceHookSurvivesCategoryReplacement { [self checkPermanentHook:NO replaceCategory:YES]; }

@end

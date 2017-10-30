//
//  GCDMulticastDelegateNode.m
//  ipjsua
//
//  Created by MacBook  on 9/19/17.
//  Copyright © 2017 CesTR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDMultiCastDelegateNode.h"

@implementation GCDMulticastDelegateNode

@synthesize delegate;       // atomic
#if __has_feature(objc_arc_weak) && !TARGET_OS_IPHONE
@synthesize unsafeDelegate; // atomic
#endif
@synthesize delegateQueue;  // non-atomic

#if __has_feature(objc_arc_weak) && !TARGET_OS_IPHONE
static BOOL SupportsWeakReferences(id delegate)
{
    // From Apple's documentation:
    //
    // > Which classes don’t support weak references?
    // >
    // > You cannot currently create weak references to instances of the following classes:
    // >
    // > NSATSTypesetter, NSColorSpace, NSFont, NSFontManager, NSFontPanel, NSImage, NSMenuView,
    // > NSParagraphStyle, NSSimpleHorizontalTypesetter, NSTableCellView, NSTextView, NSViewController,
    // > NSWindow, and NSWindowController.
    // >
    // > In addition, in OS X no classes in the AV Foundation framework support weak references.
    //
    // NSMenuView is deprecated (and not available to 64-bit applications).
    // NSSimpleHorizontalTypesetter is an internal class.
    
    if ([delegate isKindOfClass:[NSATSTypesetter class]])    return NO;
    if ([delegate isKindOfClass:[NSColorSpace class]])       return NO;
    if ([delegate isKindOfClass:[NSFont class]])             return NO;
    if ([delegate isKindOfClass:[NSFontManager class]])      return NO;
    if ([delegate isKindOfClass:[NSFontPanel class]])        return NO;
    if ([delegate isKindOfClass:[NSImage class]])            return NO;
    if ([delegate isKindOfClass:[NSParagraphStyle class]])   return NO;
    if ([delegate isKindOfClass:[NSTableCellView class]])    return NO;
    if ([delegate isKindOfClass:[NSTextView class]])         return NO;
    if ([delegate isKindOfClass:[NSViewController class]])   return NO;
    if ([delegate isKindOfClass:[NSWindow class]])           return NO;
    if ([delegate isKindOfClass:[NSWindowController class]]) return NO;
    
    return YES;
}
#endif

- (id)initWithDelegate:(id)inDelegate delegateQueue:(dispatch_queue_t)inDelegateQueue
{
    if ((self = [super init]))
    {
#if __has_feature(objc_arc_weak) && !TARGET_OS_IPHONE
        {
            if (SupportsWeakReferences(inDelegate))
            {
                delegate = inDelegate;
                delegateQueue = inDelegateQueue;
            }
            else
            {
                delegate = [NSNull null];
                
                unsafeDelegate = inDelegate;
                delegateQueue = inDelegateQueue;
            }
        }
#else
        {
            delegate = inDelegate;
            delegateQueue = inDelegateQueue;
        }
#endif
        
#if !OS_OBJECT_USE_OBJC
        if (delegateQueue)
            dispatch_retain(delegateQueue);
#endif
    }
    return self;
}

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
    if (delegateQueue)
        dispatch_release(delegateQueue);
#endif
}

@end

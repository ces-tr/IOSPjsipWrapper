//
//  GDMultiCastDelegateNode.h
//  ipjsua
//
//  Created by MacBook  on 9/19/17.
//  Copyright © 2017 CesTR. All rights reserved.
//


@interface GCDMulticastDelegateNode : NSObject {
@private
    
#if __has_feature(objc_arc_weak)
    __weak id delegate;
#if !TARGET_OS_IPHONE
    __unsafe_unretained id unsafeDelegate; // Some classes don't support weak references yet (e.g. NSWindowController)
#endif
#else
    __unsafe_unretained id delegate;
#endif
    
    dispatch_queue_t delegateQueue;
}

- (id)initWithDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

#if __has_feature(objc_arc_weak)
@property (/* atomic */ readwrite, weak) id delegate;
#if !TARGET_OS_IPHONE
@property (/* atomic */ readwrite, unsafe_unretained) id unsafeDelegate;
#endif
#else
@property (/* atomic */ readwrite, unsafe_unretained) id delegate;
#endif

@property (nonatomic, readonly) dispatch_queue_t delegateQueue;

@end

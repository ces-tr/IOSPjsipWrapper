//
//  MulticastDelegate.m
//  ClearStyle
//
//  Created by Colin Eberhardt on 13/11/2012.
//  Copyright (c) 2012 Colin Eberhardt. All rights reserved.
//

#import "SHCMulticastDelegate.h"
#import "VideoStateProtocol.h"

@implementation SHCMulticastDelegate
{
    // the array of observing delegates
    NSHashTable* _delegates;
}

- (void)doNothing {};

- (id)init
{
    if (self = [super init])
    {
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)subscribeDelegate:(id)delegate
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        [_delegates addObject:delegate];
//        dispatch_async(dispatch_get_main_queue(), ^(void){
//            //Run UI Updates
//        });
    });
    
    
}

- (void)unsubscribeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    if (delegate == nil) return;
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        [_delegates removeObject: delegate ];
        //        dispatch_async(dispatch_get_main_queue(), ^(void){
        //            //Run UI Updates
        //        });
    });
    
//    NSUInteger i;
//    for (i = [_delegates count]; i > 0; i--)
//    {
//        GCDMulticastDelegateNode *node = _delegates[i - 1];
//        
//        id nodeDelegate = node.delegate;
//#if __has_feature(objc_arc_weak) && !TARGET_OS_IPHONE
//        if (nodeDelegate == [NSNull null])
//            nodeDelegate = node.unsafeDelegate;
//#endif
        
//        if (delegate == nodeDelegate)
//        {
//            if ((delegateQueue == NULL) || (delegateQueue == node.delegateQueue))
//            {
//                // Recall that this node may be retained by a GCDMulticastDelegateEnumerator.
//                // The enumerator is a thread-safe snapshot of the delegate list at the moment it was created.
//                // To properly remove this node from list, and from the list(s) of any enumerators,
//                // we nullify the delegate via the atomic property.
//                //
//                // However, the delegateQueue is not modified.
//                // The thread-safety is hinged on the atomic delegate property.
//                // The delegateQueue is expected to properly exist until the node is deallocated.
//                
//                node.delegate = nil;
//#if __has_feature(objc_arc_weak) && !TARGET_OS_IPHONE
//                node.unsafeDelegate = nil;
//#endif
        
    
//            }
//        }
//    }
}

- (void)unsubscribeDelegate:(id)delegate
{
    [self unsubscribeDelegate:delegate delegateQueue:NULL];
}


- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([super respondsToSelector:aSelector])
        return YES;
    
    // if any of the delegates respond to this selector, return YES
    for(id delegate in _delegates)
    {
        if ([delegate respondsToSelector:aSelector])
        {
            return YES;
        }
    }
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    // can this class create the sinature?
    NSMethodSignature* signature = [super methodSignatureForSelector:aSelector];
    
    // if not, try our delegates
    if (!signature)
    {
        for(id delegate in _delegates)
        {
            if ([delegate respondsToSelector:aSelector])
            {
                return [delegate methodSignatureForSelector:aSelector];
            }
        }
    }
    
    return [[self class] instanceMethodSignatureForSelector:@selector(doNothing)];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    BOOL foundNilDelegate = NO;
    // forward the invocation to every delegate
    for(id delegate in _delegates)
    {
        if (delegate == nil){
            foundNilDelegate = YES;
        }
        else if ([delegate respondsToSelector:[anInvocation selector]])
        {
            [anInvocation invokeWithTarget:delegate];
            
        }
        
        
        
    }
    
    if (foundNilDelegate)
    {
        // At lease one weak delegate reference disappeared.
        // Remove nil delegate nodes from the list.
        //
        // This is expected to happen very infrequently.
        // This is why we handle it separately (as it requires allocating an indexSet).
        
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
        
        NSUInteger i = 0;
        
//        for (int i= (int)_delegates.count-1; i==0; i--){
//            [_delegates removeObject: objectAtIndex:i  ];
//        
//        }
        
//        for (id delegate in _delegates)
//        {
//           if (delegate == nil)
//            {
//                [indexSet addIndex:i];
//            }
//            i++;
//        }
        
        
//        [_delegates remove];
    }
    
    
    
}

@end

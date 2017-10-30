#import <Foundation/Foundation.h>
#import "SHCMulticastDelegate.h"
#import "VideoStateProtocol.h"

@interface VideoStateChangedMulticastDelegate : NSObject


+ (VideoStateChangedMulticastDelegate *) sharedInstance;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
- (void)videoStateChanged : (BOOL) enabled;
- (void) subscribe :(id)delegate;
- (void) unsubscribe :(id)delegate;

@end

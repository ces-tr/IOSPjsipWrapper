//
//  IOSPjsipWrapper.h
//  IOSPjsipWrapper
//
//  Created by MacBook  on 8/30/17.
//  Copyright © 2017 Teluu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SWAccountConfiguration.h"
#import "HandlerResponse.h"

@interface IOSPjsipWrapper : NSObject

typedef struct  {
    const char *displayName;
    const char *address;
    const char *domain;
    const char *proxy;
    const char *authScheme;
    const char *authRealm;
    const char *username;
    const char *password;
    
    
} sipAccount;


+(instancetype)iOSPjsipWrapperInstance;
-(instancetype)init NS_UNAVAILABLE;
-(void)configureEndpoint;
-(void)addSIPAccountP:(SWAccountConfiguration *)configuration completionHandler:(void(^)(SWHandlerResponse *response)) handler;
-(void)makeVideoCall;
-(void)makeCall;

@end


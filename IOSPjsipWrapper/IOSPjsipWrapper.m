//
//  IOSPjsipWrapper.m
//  IOSPjsipWrapper
//
//  Created by CesTR ces.tr.rv@gmail.com  on 8/30/17.
//

#import "IOSPjsipWrapper.h"
#import "Swig.h"
#import "Logger.h"

@implementation IOSPjsipWrapper

#ifdef THIS_FILE
    #undef THIS_FILE
    #define THIS_FILE "IOSPjsipWrapper"
#endif

static IOSPjsipWrapper *_sharedInstance = nil;


+(id)iOSPjsipWrapperInstance {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });
    
    return _sharedInstance;
}

-(instancetype)init {
    
    if (_sharedInstance) {
        return _sharedInstance;
    }
    
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    return self;
}

-(void)dealloc {
    
}


-(void)configureEndpoint {
    
    SWTransportConfiguration *udp = [SWTransportConfiguration configurationWithTransportType:SWTransportTypeUDP];
    //    udp.port = 5060;
    
    //    SWTransportConfiguration *tcp = [SWTransportConfiguration configurationWithTransportType:SWTransportTypeTCP];
    //    tcp.port = 5060;
    
    SWEndpointConfiguration *endpointConfiguration = [SWEndpointConfiguration configurationWithTransportConfigurations:@[udp]];
    
    endpointConfiguration.no_udp=NO;
    endpointConfiguration.no_tcp=YES;
    
    SWEndpoint *endpoint = [SWEndpoint sharedEndpoint];
    
    //Initialize pjsip configuration
    [endpoint configure:endpointConfiguration completionHandler:^(NSError *error) {
        
        if (error) {
            
            NSLog(@"%@", [error description]);
            
            [endpoint reset:^(NSError *error) {
                if(error) NSLog(@"%s %@",THIS_FILE, [error description]);
            }];
        }
    }];
    
    [endpoint setIncomingCallBlock:^(SWAccount *account, SWCall *call) {
        
        NSLog(@"\n\nIncoming Call : %d\n\n", (int)call.callId);
        
    }];
    
    [endpoint setAccountStateChangeBlock:^(SWAccount *account) {
        
        NSLog(@"\n\nAccount State : %ld\n\n", (long)account.accountState);
    }];
    
    [endpoint setCallStateChangeBlock:^(SWAccount *account, SWCall *call) {
        
        NSLog(@"\n\nCall State : %ld\n\n", (long)call.callState);
    }];
    
    [endpoint setCallMediaStateChangeBlock:^(SWAccount *account, SWCall *call) {
        
        NSLog(@"\n\nMedia State Changed\n\n");
    }];
}

//-(void)addSIPAccount {
//    
//    SWAccount *account = [SWAccount new];
////
//    SWAccountConfiguration *configuration = [SWAccountConfiguration new];
//    configuration.username = @"cestr_cesar_turrubiates";
//    configuration.password = @"4Kg7KFmpMY54njJR";
//    configuration.domain = @"cestr.onsip.com";
//    configuration.address = [SWAccountConfiguration addressFromUsername:@"iospjsip" domain:configuration.domain];
//    configuration.proxy = @"sip.onsip.com";
//    configuration.registerOnAdd = YES;
//    
////    DDLogDebug(@"**************ALL IS FINE  %@", configuration.address);
////    if (account!=nil)
////        DDLogDebug(@"**************calling configure  %@", configuration.address);
////    else
////        return;
//    
//    [account configure:configuration completionHandler:^(NSError *error) {
//        
//        if (error) {
//            NSLog(@"AddAccount******%@", [error description]);
//            DDLogDebug(@"**************%@", [error description]);
//        }
//        
//    }];
//}

-(void)addSIPAccountP:(SWAccountConfiguration *)configuration completionHandler:(void(^)(SWHandlerResponse *hresp))handler {
    
    SWAccount *account = [SWAccount new];
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // No explicit autorelease pool needed here.
        // The code runs in background, not strangling
        // the main run loop.
//        [self doSomeLongOperation];
        
        [account configure:configuration completionHandler:^(NSError *error) {
            
            SWHandlerResponse *resp = [SWHandlerResponse new];
            
            if (error) {
                NSLog(@"addSIPAccountP Error...  %@", [error description]);
                DDLogDebug(@"addSIPAccountP Error...  %@", [error description]);
                resp.pjError= error;
            }
            else {
                resp.pjStatus = PJ_SUCCESS;
            }
            
            if (handler) {
                handler(resp);
            }
            
            
        }];
        
        
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            // This will be called on the main thread, so that
//            // you can update the UI, for example.
//            [self longOperationDone];
//        });
//    });
    
    
}

-(void)makeVideoCall {
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] firstAccount];
    
    SWCallParameters *callparams= [SWCallParameters new];
    callparams.URI= @"cesar@cestr.onsip.com";
    callparams.videoEnabled= 1;
    
    [account makeCall: callparams completionHandler:^(NSError *error) {
        
        if (error) {
            NSLog(@"%@",[error description]);
        }
    }];
    
    
}

-(void)makeCall {
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] firstAccount];
    
    SWCallParameters *callparams= [SWCallParameters new];
    callparams.URI= @"cesar@cestr.onsip.com";
    callparams.videoEnabled= 0;
    [account makeCall:callparams completionHandler:^(NSError *error) {
        
        if (error) {
            NSLog(@"%@",[error description]);
        }
    }];


}


@end

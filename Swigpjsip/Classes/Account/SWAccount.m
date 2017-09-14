//
//  SWAccount.m
//  swig
//
//  Created by Pierre-Marc Airoldi on 2014-08-21.
//  Copyright (c) 2014 PeteAppDesigns. All rights reserved.
//

#import "SWCallParameters.h"
#import "SWAccount.h"
#import "SWAccountConfiguration.h"
#import "SWEndpointConfiguration.h"
#import "SWEndpoint.h"
#import "SWCall.h"
#import "SWUriFormatter.h"
#import "NSString+PJString.h"

#import "pjsua.h"
#import "Logger.h"

#define kRegTimeout 800

@interface SWAccount ()

@property (nonatomic, strong) SWAccountConfiguration *configuration;
@property (nonatomic, strong) NSMutableArray *calls;

@end

@implementation SWAccount

-(instancetype)init {
    
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    _calls = [NSMutableArray new];
    
    return self;
}

-(void)dealloc {
    
}

-(void)setAccountId:(NSInteger)accountId {
    
    _accountId = accountId;
}

-(void)setAccountState:(SWAccountState)accountState {
    
    [self willChangeValueForKey:@"accountState"];
    _accountState = accountState;
    [self didChangeValueForKey:@"accountState"];
}

-(void)setAccountConfiguration:(SWAccountConfiguration *)accountConfiguration {
    
    [self willChangeValueForKey:@"accountConfiguration"];
    _accountConfiguration = accountConfiguration;
    [self didChangeValueForKey:@"accountConfiguration"];
}

-(void)configure:(SWAccountConfiguration *)configuration completionHandler:(void(^)(NSError *error))handler {
    
    SWEndpoint *endpoint = [SWEndpoint sharedEndpoint];
    
    self.accountConfiguration = configuration;
    
    if (!self.accountConfiguration.address) {
        self.accountConfiguration.address = [SWAccountConfiguration addressFromUsername:self.accountConfiguration.username domain:self.accountConfiguration.domain];
    }
    
    NSString *tcpSuffix = @"";
    
    if ([[SWEndpoint sharedEndpoint] hasTCPConfiguration]) {
        tcpSuffix = @";transport=TCP";
    }
    
    
    pjsua_acc_config acc_cfg;
    pjsua_acc_config_default(&acc_cfg);

    acc_cfg.id = [[SWUriFormatter sipUri:[self.accountConfiguration.address stringByAppendingString:tcpSuffix] withDisplayName:self.accountConfiguration.displayName] pjString];
    acc_cfg.reg_uri = [[SWUriFormatter sipUri:[self.accountConfiguration.domain stringByAppendingString:tcpSuffix]] pjString];
    acc_cfg.register_on_acc_add = self.accountConfiguration.registerOnAdd ? PJ_TRUE : PJ_FALSE;;
    acc_cfg.publish_enabled = self.accountConfiguration.publishEnabled ? PJ_TRUE : PJ_FALSE;
    acc_cfg.reg_timeout = kRegTimeout;
    
    acc_cfg.cred_count = 1;
    acc_cfg.cred_info[0].scheme = [self.accountConfiguration.authScheme pjString];
    acc_cfg.cred_info[0].realm = [self.accountConfiguration.authRealm pjString];
    acc_cfg.cred_info[0].username = [self.accountConfiguration.username pjString];
    acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    acc_cfg.cred_info[0].data = [self.accountConfiguration.password pjString];
    
    if (!self.accountConfiguration.proxy) {
        acc_cfg.proxy_cnt = 0;
    }
    
    else {
        acc_cfg.proxy_cnt = 1;
        acc_cfg.proxy[0] = [[SWUriFormatter sipUri:[self.accountConfiguration.proxy stringByAppendingString:tcpSuffix]] pjString];
    }
    
    pj_status_t status;
    
    
    acc_cfg.rtp_cfg = endpoint.endpointConfiguration.rtp_cfg;
    [self app_config_init_video: (&acc_cfg) ];
    
    status = pjsua_acc_add(&acc_cfg, PJ_TRUE, (int*)&_accountId);
    
    
    if (status != PJ_SUCCESS) {
        
        NSError *error = [NSError errorWithDomain:@"Error adding account" code:status userInfo:nil];
        
        if (handler) {
            handler(error);
        }
        
        return;
    }
    
    else {
        [[SWEndpoint sharedEndpoint] addAccount:self];
    }
    
    if (!self.accountConfiguration.registerOnAdd) {
        [self connect:handler];
    }
    
    else {
        
        if (handler) {
            handler(nil);
        }
    }
}

#ifdef PJSUA_HAS_VIDEO
-(void) app_config_init_video:(pjsua_acc_config *) acc_cfg
{
    SWEndpoint *endpoint = [SWEndpoint sharedEndpoint];
    
    acc_cfg->vid_in_auto_show = (int)endpoint.endpointConfiguration.in_auto_show;
    acc_cfg->vid_out_auto_transmit = (int)endpoint.endpointConfiguration.out_auto_transmit;//app_config.vid.out_auto_transmit;
    /* Note that normally GUI application will prefer a borderless
     * window.
     */
    acc_cfg->vid_wnd_flags = PJMEDIA_VID_DEV_WND_BORDER | PJMEDIA_VID_DEV_WND_RESIZABLE;
    acc_cfg->vid_cap_dev = (int)endpoint.endpointConfiguration.vcapture_dev; //   app_config.vid.vcapture_dev;
    acc_cfg->vid_rend_dev = (int)endpoint.endpointConfiguration.vrender_dev;
    
    
//   TODO Play avi video
//    if (endpoint.endpointConfiguration.avi_auto_play &&
//        endpoint.endpointConfiguration.avi_def_idx != PJSUA_INVALID_ID &&
//        endpoint.endpointConfiguration.avi[endpoint.endpointConfiguration.avi_def_idx].dev_id != PJMEDIA_VID_INVALID_DEV)
//    {
//        acc_cfg->vid_cap_dev = app_config.avi[app_config.avi_def_idx].dev_id;
//    }
}
#else
void app_config_init_video(pjsua_acc_config *acc_cfg)
{
    PJ_UNUSED_ARG(acc_cfg);
}
#endif



-(void)connect:(void(^)(NSError *error))handler {
    
    //FIX: registering too often will cause the server to possibly return error
        
    pj_status_t status;
    
    status = pjsua_acc_set_registration((int)self.accountId, PJ_TRUE);
    
    if (status != PJ_SUCCESS) {
        
        NSError *error = [NSError errorWithDomain:@"Error setting registration" code:status userInfo:nil];
        
        if (handler) {
            handler(error);
        }
        
        return;
    }
    
    status = pjsua_acc_set_online_status((int)self.accountId, PJ_TRUE);
    
    if (status != PJ_SUCCESS) {
        
        NSError *error = [NSError errorWithDomain:@"Error setting online status" code:status userInfo:nil];
        
        if (handler) {
            handler(error);
        }
        
        return;
    }
    
    if (handler) {
        handler(nil);
    }
}

-(void)disconnect:(void(^)(NSError *error))handler {
    
    pj_status_t status;
    
    status = pjsua_acc_set_online_status((int)self.accountId, PJ_FALSE);
    
    if (status != PJ_SUCCESS) {
        
        NSError *error = [NSError errorWithDomain:@"Error setting online status" code:status userInfo:nil];
        
        if (handler) {
            handler(error);
        }
        
        return;
    }
    
    status = pjsua_acc_set_registration((int)self.accountId, PJ_FALSE);
    
    if (status != PJ_SUCCESS) {
        
        NSError *error = [NSError errorWithDomain:@"Error setting registration" code:status userInfo:nil];
        
        if (handler) {
            handler(error);
        }
        
        return;
    }
    
    if (handler) {
        handler(nil);
    }
}

-(void)accountStateChanged {
    
    pjsua_acc_info accountInfo;
    pjsua_acc_get_info((int)self.accountId, &accountInfo);
    
    pjsip_status_code code = accountInfo.status;
    
    //TODO make status offline/online instead of offline/connect
    //status would be disconnected, online, and offline, isConnected could return true if online/offline
    
    if (code == 0 || accountInfo.expires == -1) {
        self.accountState = SWAccountStateDisconnected;
    }
    
    else if (PJSIP_IS_STATUS_IN_CLASS(code, 100) || PJSIP_IS_STATUS_IN_CLASS(code, 300)) {
        self.accountState = SWAccountStateConnecting;
    }
    
    else if (PJSIP_IS_STATUS_IN_CLASS(code, 200)) {
        self.accountState = SWAccountStateConnected;
    }
    
    else {
        self.accountState = SWAccountStateDisconnected;
    }
}

-(BOOL)isValid {
    
    return pjsua_acc_is_valid((int)self.accountId);
}

#pragma Call Management

-(void)addCall:(SWCall *)call {
    
    [self.calls addObject:call];
    
    //TODO:: setup blocks
}

-(void)removeCall:(NSUInteger)callId {
    
    SWCall *call = [self lookupCall:callId];
    
    if (call) {
        [self.calls removeObject:call];
    }
    
    call = nil;
}

-(SWCall *)lookupCall:(NSInteger)callId {
    
    NSUInteger callIndex = [self.calls indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        
        SWCall *call = (SWCall *)obj;
        
        if (call.callId == callId && call.callId != PJSUA_INVALID_ID) {
            return YES;
        }
        
        return NO;
    }];
    
    if (callIndex != NSNotFound) {
        return [self.calls objectAtIndex:callIndex]; //TODO add more management
    }
    
    else {
        return nil;
    }
}

-(SWCall *)firstCall {
    
    if (self.calls.count > 0) {
        return self.calls[0];
    }
    
    else {
        return nil;
    }
}

-(void)endAllCalls {
    
    for (SWCall *call in self.calls) {
        [call hangup:nil];
    }
}


-(void)makeCall:(SWCallParameters *)callParams completionHandler:(void(^)(NSError *error))handler {
    
    pj_status_t status;
    NSError *error;
    
    pjsua_call_id callIdentifier;
    pj_str_t uri = [[SWUriFormatter sipUri:callParams.URI fromAccount:self] pjString];
    
    pjsua_call_setting  call_opt;
    pjsua_call_setting_default(&call_opt);
    
    call_opt.vid_cnt = (int)callParams.videoEnabled;
    
    
    
    status =pjsua_call_make_call((int)_accountId, &uri, &call_opt, NULL,
                         NULL, &callIdentifier);
    
    if (status != PJ_SUCCESS) {
        
        error = [NSError errorWithDomain:@"Error hanging up call" code:0 userInfo:nil];
    }
    
    else {
        
        SWCall *call = [SWCall callWithId:callIdentifier accountId:self.accountId inBound:NO];
        
        [self addCall:call];
        
    }
    
    if (handler) {
        handler(error);
    }
}

@end

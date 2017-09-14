//
//  SWEndpoint.m
//  swig
//
//  Created by Pierre-Marc Airoldi on 2014-08-20.
//  Copyright (c) 2014 PeteAppDesigns. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SWEndpoint.h"
#import "SWTransportConfiguration.h"
#import "SWEndpointConfiguration.h"
#import "SWAccount.h"
#import "SWCall.h"
#import "NSString+PJString.h"
#import <AFNetworkReachabilityManager.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <libextobjc/extobjc.h>
#import "Logger.h"
#import "Utils.h"
#import <pjsua.h>




#define KEEP_ALIVE_INTERVAL 600

typedef void (^SWAccountStateChangeBlock)(SWAccount *account);
typedef void (^SWIncomingCallBlock)(SWAccount *account, SWCall *call);
typedef void (^SWCallStateChangeBlock)(SWAccount *account, SWCall *call);
typedef void (^SWCallMediaStateChangeBlock)(SWAccount *account, SWCall *call);

//thread statics
static pj_thread_t *thread;

static pjsua_config cfg;
static pjsua_logging_config log_cfg;
static pjsua_media_config media_cfg;


//callback functions

static void SWOnIncomingCall(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);

static void SWOnCallMediaState(pjsua_call_id call_id);

static void SWOnCallState(pjsua_call_id call_id, pjsip_event *e);

static void SWOnCallTransferStatus(pjsua_call_id call_id, int st_code, const pj_str_t *st_text, pj_bool_t final, pj_bool_t *p_cont);

static void SWOnCallReplaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id);

static void SWOnRegState(pjsua_acc_id acc_id);

static void SWOnNatDetect(const pj_stun_nat_detect_result *res);

@interface SWEndpoint ()

@property (nonatomic, copy) SWIncomingCallBlock incomingCallBlock;
@property (nonatomic, copy) SWAccountStateChangeBlock accountStateChangeBlock;
@property (nonatomic, copy) SWCallStateChangeBlock callStateChangeBlock;
@property (nonatomic, copy) SWCallMediaStateChangeBlock callMediaStateChangeBlock;
@property (nonatomic) pj_thread_t *thread;

@end

@implementation SWEndpoint

static SWEndpoint *_sharedEndpoint = nil;

//extern pjsua_app_config	    app_config;

+(id)sharedEndpoint {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedEndpoint = [self new];
    });
    
    return _sharedEndpoint;
}

-(instancetype)init {
    
    if (_sharedEndpoint) {
        return _sharedEndpoint;
    }
    
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 0;
    fileLogger.maximumFileSize = 0;
    
    [DDLog addLogger:fileLogger];
    
    _accounts = [[NSMutableArray alloc] init];
    
    
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"Ringtone" withExtension:@"aif"];
    
    _ringtone = [[SWRingtone alloc] initWithFileAtPath:fileURL];
    
    //TODO check if the reachability happens in background
    //FIX make sure connect doesnt get called too often
    //IP Change logic
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        if ([AFNetworkReachabilityManager sharedManager].reachableViaWiFi) {
            
            [self performSelectorOnMainThread:@selector(keepAlive) withObject:nil waitUntilDone:YES];
        }
        
        else if ([AFNetworkReachabilityManager sharedManager].reachableViaWWAN) {
            [self performSelectorOnMainThread:@selector(keepAlive) withObject:nil waitUntilDone:YES];
        }
        
        else {
            //offline
        }
    }];
    
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(handleEnteredBackground:) name: UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(handleApplicationWillTeminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    return self;
}

-(void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    
    [self reset:^(NSError *error) {
        if (error) DDLogDebug(@"%@", [error description]);
    }];
}

#pragma Notification Methods

-(void)handleEnteredBackground:(NSNotification *)notification {
    
    UIApplication *application = (UIApplication *)notification.object;
    
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    self.ringtone.volume = 0.0;
    
    [self performSelectorOnMainThread:@selector(keepAlive) withObject:nil waitUntilDone:YES];
    
    [application setKeepAliveTimeout:KEEP_ALIVE_INTERVAL handler: ^{
        [self performSelectorOnMainThread:@selector(keepAlive) withObject:nil waitUntilDone:YES];
    }];
}

-(void)handleApplicationWillTeminate:(NSNotification *)notification {
    
    UIApplication *application = (UIApplication *)notification.object;
    
    //TODO hangup all calls
    //TODO remove all accounts
    //TODO close all transports
    //TODO reset endpoint
    
    for (int i = 0; i < [self.accounts count]; ++i) {
        
        SWAccount *account = [self.accounts objectAtIndex:i];
        
        dispatch_semaphore_t semaphone = dispatch_semaphore_create(0);
        
        @weakify(account);
        [account disconnect:^(NSError *error) {
            
            @strongify(account);
            account = nil;
            
            dispatch_semaphore_signal(semaphone);
        }];
        
        dispatch_semaphore_wait(semaphone, DISPATCH_TIME_FOREVER);
    }
    
    NSMutableArray *mutableAccounts = [self.accounts mutableCopy];
    
    [mutableAccounts removeAllObjects];
    
    self.accounts = mutableAccounts;
    
    [self reset:^(NSError *error) {
        
        if (error) {
            DDLogDebug(@"%@", [error description]);
        }
    }];
    
    [application setApplicationIconBadgeNumber:0];
}

-(void)keepAlive {
    
    if (pjsua_get_state() != PJSUA_STATE_RUNNING) {
        return;
    }
    
    [self registerThread];
    
    for (SWAccount *account in self.accounts) {
        
        if (account.isValid) {
            
            dispatch_semaphore_t semaphone = dispatch_semaphore_create(0);
            
            [account connect:^(NSError *error) {
                
                dispatch_semaphore_signal(semaphone);
            }];
            
            dispatch_semaphore_wait(semaphone, DISPATCH_TIME_FOREVER);
        }
        
        else {
            
            dispatch_semaphore_t semaphone = dispatch_semaphore_create(0);
            
            [account disconnect:^(NSError *error) {
                
                dispatch_semaphore_signal(semaphone);
            }];
            
            dispatch_semaphore_wait(semaphone, DISPATCH_TIME_FOREVER);
        }
    }
}

#pragma Endpoint Methods

-(void)setEndpointConfiguration:(SWEndpointConfiguration *)endpointConfiguration {
    
    [self willChangeValueForKey:@"endpointConfiguration"];
    _endpointConfiguration = endpointConfiguration;
    [self didChangeValueForKey:@"endpointConfiguration"];
}

-(void)setRingtone:(SWRingtone *)ringtone {
    
    [self willChangeValueForKey:@"ringtone"];
    
    if (_ringtone.isPlaying) {
        [_ringtone stop];
        _ringtone = ringtone;
        [_ringtone start];
    }
    
    else {
        _ringtone = ringtone;
    }
    
    [self didChangeValueForKey:@"ringtone"];
}

-(void)configure:(SWEndpointConfiguration *)configuration completionHandler:(void(^)(NSError *error))handler {
    
//    [self initpjsuaApp];
//    appRun();
    
    
//    return;
    //TODO add lock to this method
    
    _endpointConfiguration = configuration;
    unsigned i;
    pj_status_t status;

    
    status = pjsua_create();
    
    if (status != PJ_SUCCESS) {
        
        NSError *error = [NSError errorWithDomain:@"Error creating pjsua" code:status userInfo:nil];
        
        if (handler) {
            handler(error);
        }
        
        return;
    }
    
    /* Create pool for application */
    
    _pjPool = pjsua_pool_create("pjsua-app", 1000, 1000);

    pj_pool_t tmp_pool;
    tmp_pool = *pjsua_pool_create("tmp-pjsua", 1000, 1000);;
    
    [self load_default_configs];
    
    cfg.cb.on_incoming_call = &SWOnIncomingCall;
    cfg.cb.on_call_media_state = &SWOnCallMediaState;
    cfg.cb.on_call_state = &SWOnCallState;
//    cfg.cb.on_call_transfer_status = &SWOnCallTransferStatus;
//    cfg.cb.on_call_replaced = &SWOnCallReplaced;
//    cfg.cb.on_reg_state = &SWOnRegState;
//    cfg.cb.on_nat_detect = &SWOnNatDetect;
    
    /*Test callbacks*/
//    cfg.cb.on_call_media_event= &SWOnCallMediaEvent;
    /**/
    
    cfg.max_calls = (unsigned int)self.endpointConfiguration.maxCalls;
    
    log_cfg.level = (unsigned int)self.endpointConfiguration.logLevel;
    log_cfg.console_level = (unsigned int)self.endpointConfiguration.logConsoleLevel;
    log_cfg.log_filename = [self.endpointConfiguration.logFilename pjString];
    log_cfg.log_file_flags = (unsigned int)self.endpointConfiguration.logFileFlags;
    
    media_cfg.clock_rate = (unsigned int)self.endpointConfiguration.clockRate;
    media_cfg.snd_clock_rate = (unsigned int)self.endpointConfiguration.sndClockRate;
    
    /* Set sound device latency */
    if (configuration.capture_lat > 0)
        media_cfg.snd_rec_latency = (int)configuration.capture_lat;
    if ([configuration capture_lat])
        media_cfg.snd_play_latency = (int)configuration.playback_lat;
    
    
    status = pjsua_init(&cfg, &log_cfg, &media_cfg);
    
    if (status != PJ_SUCCESS) {
        
        NSError *error = [NSError errorWithDomain:@"Error initializing pjsua" code:status userInfo:nil];
        
        if (handler) {
            handler(error);
        }
        
        return;
    }
    
    //TODO autodetect port by checking transportId!!!!
    
    for (SWTransportConfiguration *transport in self.endpointConfiguration.transportConfigurations) {
        
        pjsua_transport_config transportConfig;
        pjsua_transport_id transportId;
        
        pjsua_transport_config_default(&transportConfig);
        
        pjsip_transport_type_e transportType = (pjsip_transport_type_e)transport.transportType;
        
        status = pjsua_transport_create(transportType, &transportConfig, &transportId);
        
        if (status != PJ_SUCCESS) {
            
            NSError *error = [NSError errorWithDomain:@"Error creating pjsua transport" code:status userInfo:nil];
            
            if (handler) {
                handler(error);
            }
            
            return;
        }
    }
    
    [self start:handler];
    
    [Utils listPjsuaCodecs];
    
}

-(void) load_default_configs{
    
//    pjsua_config_default(&cfg);
//    pjsua_logging_config_default(&log_cfg);
//    pjsua_media_config_default(&media_cfg);
    
    char tmp[80];
    unsigned i;
//    pjsua_app_config *cfg = &cfg;
    
    pjsua_config_default(&cfg);
    pj_ansi_sprintf(tmp, "PJSUA v%s %s", pj_get_version(), pj_get_sys_info()->info.ptr);
    pj_strdup2_with_null([[SWEndpoint sharedEndpoint] pjPool], &cfg.user_agent, tmp);
    
    pjsua_logging_config_default(&log_cfg);
    pjsua_media_config_default(&media_cfg);
    //Inside transport creation
//    pjsua_transport_config_default(&cfg->udp_cfg);
//    cfg->udp_cfg.port = 5060;
//    pjsua_transport_config_default(&cfg->rtp_cfg);
//    cfg->rtp_cfg.port = 4000;
    
    _endpointConfiguration.redir_op = PJSIP_REDIRECT_ACCEPT_REPLACE;
    _endpointConfiguration.duration = SWECNO_LIMIT_DURATION;
    _endpointConfiguration.wav_id = PJSUA_INVALID_ID;
    _endpointConfiguration.rec_id = PJSUA_INVALID_ID;
    _endpointConfiguration.wav_port = PJSUA_INVALID_ID;
    _endpointConfiguration.rec_port = PJSUA_INVALID_ID;
    _endpointConfiguration.mic_level = _endpointConfiguration.speaker_level = 1.0;
    _endpointConfiguration.capture_dev = PJSUA_INVALID_ID;
    _endpointConfiguration.playback_dev = PJSUA_INVALID_ID;
    _endpointConfiguration.capture_lat = PJMEDIA_SND_DEFAULT_REC_LATENCY;
    _endpointConfiguration.playback_lat = PJMEDIA_SND_DEFAULT_PLAY_LATENCY;
    _endpointConfiguration.ringback_slot = PJSUA_INVALID_ID;
    _endpointConfiguration.ring_slot = PJSUA_INVALID_ID;
    _endpointConfiguration.aud_cnt = 1;
    
    //video config
    _endpointConfiguration.vcapture_dev = PJMEDIA_VID_DEFAULT_CAPTURE_DEV;
    _endpointConfiguration.vrender_dev = PJMEDIA_VID_DEFAULT_RENDER_DEV;
    
    
    _endpointConfiguration.avi_def_idx = PJSUA_INVALID_ID;
    
    _endpointConfiguration.vid_cnt = 1;
    _endpointConfiguration.in_auto_show = PJ_TRUE;
    _endpointConfiguration.out_auto_transmit = PJ_TRUE;
    
//    _endpointConfiguration.no_udp= NO;
//    _endpointConfiguration.no_tcp= YES;
    pjsua_transport_config rtp_cfg;
    pjsua_transport_config_default(&rtp_cfg);
    rtp_cfg.port = 4000;
    
    _endpointConfiguration.rtp_cfg= rtp_cfg;
    
    media_cfg.quality = 5; //--quality (expecting 0-10")
//    if (media_cfg.quality > 10) {
//        PJ_LOG(1,("Initpjsua",
//                  "Error: invalid --quality (expecting 0-10"));
//        media_cfg.quality=5;
//    }
    
    
    
}


- (void)enableSoundDevice {
       static pj_thread_desc a_thread_desc;
        static pj_thread_t *a_thread;
    
        if (!pj_thread_is_registered()) {
                pj_thread_register("ipjsua", a_thread_desc, &a_thread);
            }
    
        pj_status_t status;
        status = pjsua_set_snd_dev(PJMEDIA_AUD_DEFAULT_CAPTURE_DEV, PJMEDIA_AUD_DEFAULT_PLAYBACK_DEV);
        if (status != PJ_SUCCESS) NSLog(@"Failure in enabling sound device");
    
    }


-(BOOL)hasTCPConfiguration {
    
    NSUInteger index = [self.endpointConfiguration.transportConfigurations indexOfObjectPassingTest:^BOOL(SWTransportConfiguration *obj, NSUInteger idx, BOOL *stop) {
        
        if (obj.transportType == SWTransportTypeTCP || obj.transportType == SWTransportTypeTCP6) {
            return YES;
            *stop = YES;
        }
        
        else {
            return NO;
        }
    }];
    
    if (index == NSNotFound) {
        return NO;
    }
    
    else {
        return YES;
    }
}

-(void)registerThread {
    
    pjsua_state state;
    state= pjsua_get_state();
    
    if (pjsua_get_state() != PJSUA_STATE_RUNNING) {
        return;
    }
    
    if (!pj_thread_is_registered()) {
        pj_thread_register("swig", NULL, &thread);
    }
    
    else {
        thread = pj_thread_this();
    }
    
    if (!_pjPool) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            _pjPool = pjsua_pool_create("swig-pjsua", 512, 512);
            _pjPool = pjsua_pool_create("pjsua-app", 1000, 1000);
            
        });
    }
}

-(void)start:(void(^)(NSError *error))handler {
    
    pj_status_t status = pjsua_start();
    
    if (status != PJ_SUCCESS) {
        
        NSError *error = [NSError errorWithDomain:@"Error starting pjsua" code:status userInfo:nil];
        
        if (handler) {
            handler(error);
        }
        
        return;
    }
    
    //Initialize h264 codec
    
    const pj_str_t codec_id = {"H264", 4};
    int bitrate;
    pjmedia_vid_codec_param param;
    pjsua_vid_codec_get_param(&codec_id, &param);
    param.enc_fmt.det.vid.size.w = 640; //656x656
    param.enc_fmt.det.vid.size.h = 480;
    param.enc_fmt.det.vid.fps.num = 25;
    param.enc_fmt.det.vid.fps.denum = 1;
    
    bitrate = 1000 * atoi("512");
    param.enc_fmt.det.vid.avg_bps = bitrate;
    param.enc_fmt.det.vid.max_bps = bitrate;
    
    param.dec_fmt.det.vid.size.w = 640;
    param.dec_fmt.det.vid.size.h = 480;
    param.dec_fmt.det.vid.fps.num = 25;
    param.dec_fmt.det.vid.fps.denum = 1;
    
    param.dec_fmtp.cnt = 2;
    param.dec_fmtp.param[0].name = pj_str("profile-level-id");
    param.dec_fmtp.param[0].val = pj_str("42E01E");
    param.dec_fmtp.param[1].name = pj_str("packetization-mode");
    param.dec_fmtp.param[1].val = pj_str("1");
    
    pjsua_vid_codec_set_param(&codec_id, &param);
    
    if (handler) {
        handler(nil);
    }
}

-(void)reset:(void(^)(NSError *error))handler {
    
    //TODO shutdown agent correctly. stop all calls, destroy all accounts
    
    for (SWAccount *account in self.accounts) {
        
        [account endAllCalls];
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        [account disconnect:^(NSError *error) {
            dispatch_semaphore_signal(sema);
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    
//    NSMutableArray *mutableArray = [self.accounts mutableCopy];
//    
//    [mutableArray removeAllObjects];
//    
//    self.accounts = mutableArray;
    
//    pj_status_t status = pjsua_destroy();
//    
//    if (status != PJ_SUCCESS) {
//        
//        NSError *error = [NSError errorWithDomain:@"Error destroying pjsua" code:status userInfo:nil];
//        
//        if (handler) {
//            handler(error);
//        }
//        
//        return;
//    }
//    
//    if (handler) {
//        handler(nil);
//    }    
}

#pragma Account Management

-(void)addAccount:(SWAccount *)account {
    
    if (![self lookupAccount:account.accountId]) {
        
        NSMutableArray *mutableArray = [self.accounts mutableCopy];
        [mutableArray addObject:account];
        
        self.accounts = mutableArray;
    }
}

-(void)removeAccount:(SWAccount *)account {
 
    if ([self lookupAccount:account.accountId]) {
    
        NSMutableArray *mutableArray = [self.accounts mutableCopy];
        [mutableArray removeObject:account];
        
        self.accounts = mutableArray;
    }
}

-(SWAccount *)lookupAccount:(NSInteger)accountId {
    
    NSUInteger accountIndex = [self.accounts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        
        SWAccount *account = (SWAccount *)obj;
        
        if (account.accountId == accountId && account.accountId != PJSUA_INVALID_ID) {
            return YES;
        }
        
        return NO;
    }];
    
    if (accountIndex != NSNotFound) {
        return [self.accounts objectAtIndex:accountIndex]; //TODO add more management
    }
    
    else {
        return nil;
    }
}
-(SWAccount *)firstAccount {
    
    if (self.accounts.count > 0) {
        return self.accounts[0];
    }
    
    else {
        return nil;
    }
}


#pragma Block Parameters

-(void)setAccountStateChangeBlock:(void(^)(SWAccount *account))accountStateChangeBlock {
    
    _accountStateChangeBlock = accountStateChangeBlock;
}

-(void)setIncomingCallBlock:(void(^)(SWAccount *account, SWCall *call))incomingCallBlock {
    
    _incomingCallBlock = incomingCallBlock;
}

-(void)setCallStateChangeBlock:(void(^)(SWAccount *account, SWCall *call))callStateChangeBlock {
    
    _callStateChangeBlock = callStateChangeBlock;
}

-(void)setCallMediaStateChangeBlock:(void(^)(SWAccount *account, SWCall *call))callMediaStateChangeBlock {
    
    _callMediaStateChangeBlock = callMediaStateChangeBlock;
}

#pragma PJSUA Callbacks

static void SWOnRegState(pjsua_acc_id acc_id) {
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] lookupAccount:acc_id];
    
    if (account) {
        
        [account accountStateChanged];
        
        if ([SWEndpoint sharedEndpoint].accountStateChangeBlock) {
            [SWEndpoint sharedEndpoint].accountStateChangeBlock(account);
        }
        
        if (account.accountState == SWAccountStateDisconnected) {
            [[SWEndpoint sharedEndpoint] removeAccount:account];
        }
    }
}

static void SWOnIncomingCall(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] lookupAccount:acc_id];
    
    if (account) {
        
        SWCall *call = [SWCall callWithId:call_id accountId:acc_id inBound:YES];
        
        if (call) {
            
            [account addCall:call];
            
            [call callStateChanged];
            
            if ([SWEndpoint sharedEndpoint].incomingCallBlock) {
                [SWEndpoint sharedEndpoint].incomingCallBlock(account, call);
            }
        }
    }
}

static void SWOnCallState(pjsua_call_id call_id, pjsip_event *e) {
    
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
    
    if (account) {
        
        SWCall *call = [account lookupCall:call_id];
        
        if (call) {
            
            [call callStateChanged];
            
            if ([SWEndpoint sharedEndpoint].callStateChangeBlock) {
                [SWEndpoint sharedEndpoint].callStateChangeBlock(account, call);
            }
            
            if (call.callState == SWCallStateDisconnected) {
                [account removeCall:call.callId];
            }
        }
    }
}

static void SWOnCallMediaState(pjsua_call_id call_id) {
    
    pjsua_call_info callInfo;
    pjsua_call_get_info(call_id, &callInfo);
    
//    pjsua_call_info call_info;
    
    unsigned mi;
    pj_bool_t has_error = PJ_FALSE;
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] lookupAccount:callInfo.acc_id];
    
    if (account  ) {
        
        SWCall *call = [account lookupCall:call_id];
       
        if (call ) {
        
            for (mi=0; mi<callInfo.media_cnt; ++mi) {
                
                pjsua_call_vid_strm_op_param op_param;
                op_param.med_idx= -1;
                op_param.dir= PJMEDIA_DIR_ENCODING_DECODING;
                op_param.cap_dev= PJMEDIA_VID_DEFAULT_CAPTURE_DEV;
                
                pjsua_call_set_vid_strm(callInfo.id, PJSUA_CALL_VID_STRM_SEND_KEYFRAME, &op_param);
                
                
                printf("Logger: SWOnCallMediaState looping ");
                
//                on_call_generic_media_state2(&callInfo,mi,&has_error);
                
                switch (callInfo.media[mi].type) {
                    case PJMEDIA_TYPE_AUDIO:
                        printf("SWOnCallMediaState Logger: case audio ");
                        
                        if ([SWEndpoint sharedEndpoint].callMediaStateChangeBlock) {
                            [SWEndpoint sharedEndpoint].callMediaStateChangeBlock(account, call);
                        }
                        [call audioStateChanged: &callInfo  mi:mi haserror: &has_error];

                        break;
                    case PJMEDIA_TYPE_VIDEO:
                        printf("SWOnCallMediaState Logger: case video ");

                        [call videoStateChanged: &callInfo  mi:mi haserror: &has_error];
                        break;
                    default:
                        // Make gcc happy about enum not handled by switch/case /
                        printf("SWOnCallMediaState Logger: default case ");
                        break;
                }
                
            }
            if (has_error) {
                pj_str_t reason = pj_str("Media failed");
                pjsua_call_hangup(call_id, 500, &reason, NULL);
            }
            
#if PJSUA_HAS_VIDEO
            /* Check if remote has just tried to enable video */
            if (callInfo.rem_offerer && callInfo.rem_vid_cnt)
            {
                int vid_idx;
                
                /* Check if there is active video */
                vid_idx = pjsua_call_get_vid_stream_idx(call_id);
                if (vid_idx == -1 || callInfo.media[vid_idx].dir == PJMEDIA_DIR_NONE) {
                    PJ_LOG(3,("SWEndpoint.m",
                              "Just rejected incoming video offer on call %d, "
                              "use \"vid call enable %d\" or \"vid call add\" to "
                              "enable video!", call_id, vid_idx));
                }
            }
#endif
        }
    }
}



/* General processing for media state. "mi" is the media index */
static void on_call_generic_media_state2(pjsua_call_info *ci, unsigned mi,
                                        pj_bool_t *has_error)
{
    const char *status_name[] = {
        "None",
        "Active",
        "Local hold",
        "Remote hold",
        "Error"
    };
    
    PJ_UNUSED_ARG(has_error);
    
    pj_assert(ci->media[mi].status <= PJ_ARRAY_SIZE(status_name));
    pj_assert(PJSUA_CALL_MEDIA_ERROR == 4);
    
    PJ_LOG(4,("Media State", "Call %d media %d [type=%s], status is %s",
              ci->id, mi, pjmedia_type_name(ci->media[mi].type),
              status_name[ci->media[mi].status]));
}


//TODO: implement these
static void SWOnCallTransferStatus(pjsua_call_id call_id, int st_code, const pj_str_t *st_text, pj_bool_t final, pj_bool_t *p_cont) {
    
}

static void SWOnCallReplaced(pjsua_call_id old_call_id, pjsua_call_id new_call_id) {
    
}

static void SWOnNatDetect(const pj_stun_nat_detect_result *res){
    
}

/* Callback on media events */
static void SWOnCallMediaEvent(pjsua_call_id call_id,
                                unsigned med_idx,
                                pjmedia_event *event)
{
    char event_name[5];
    
//    PJ_LOG(5,(THIS_FILE, "Event %s",
//              pjmedia_fourcc_name(event->type, event_name)));
    
#if PJSUA_HAS_VIDEO
    if (event->type == PJMEDIA_EVENT_FMT_CHANGED) {
        /* Adjust renderer window size to original video size */
        pjsua_call_info ci;
        
        pjsua_call_get_info(call_id, &ci);
        
        if ((ci.media[med_idx].type == PJMEDIA_TYPE_VIDEO) &&
            (ci.media[med_idx].dir & PJMEDIA_DIR_DECODING))
        {
            pjsua_vid_win_id wid;
            pjmedia_rect_size size;
            pjsua_vid_win_info win_info;
            
            wid = ci.media[med_idx].stream.vid.win_in;
            pjsua_vid_win_get_info(wid, &win_info);
            
            size = event->data.fmt_changed.new_fmt.det.vid.size;
            if (size.w != win_info.size.w || size.h != win_info.size.h) {
                pjsua_vid_win_set_size(wid, &size);
                
                /* Re-arrange video windows */
                //arrange_window(PJSUA_INVALID_ID);
            }
        }
    }
#else
    PJ_UNUSED_ARG(call_id);
    PJ_UNUSED_ARG(med_idx);
    PJ_UNUSED_ARG(event);
#endif
}



#pragma Setters/Getters

-(void)setPjPool:(pj_pool_t *)pjPool {
    
     _pjPool = pjPool;
    
}

-(void)setAccounts:(NSArray *)accounts {
    
    [self willChangeValueForKey:@"accounts"];
    _accounts = accounts;
    [self didChangeValueForKey:@"accounts"];
}

@end

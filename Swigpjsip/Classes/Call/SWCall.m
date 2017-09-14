//
//  SWCall.m
//  swig
//
//  Created by Pierre-Marc Airoldi on 2014-08-21.
//  Copyright (c) 2014 PeteAppDesigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWCall.h"
#import "SWAccount.h"
#import "SWEndpoint.h"
#import "SWUriFormatter.h"
#import "NSString+PJString.h"
#import "pjsua.h"
#import <AVFoundation/AVFoundation.h>
#import "SWMutableCall.h"
#import "Logger.h"
#import "Utils.h"




@interface SWCall ()

@property (nonatomic, strong) UILocalNotification *notification;
@property (nonatomic, strong) SWRingback *ringback;
@property (nonatomic) BOOL speaker;
@property (nonatomic) BOOL mute;

@end


@implementation SWCall

-(instancetype)init {
    
    NSAssert(NO, @"never call init directly use init with call id");
    
    return nil;
}

-(instancetype)initWithCallId:(NSUInteger)callId accountId:(NSInteger)accountId inBound:(BOOL)inbound {
    
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    _inbound = inbound;
    
    if (_inbound) {
        _missed = YES;
    }
    
    _callState = SWCallStateReady;
    _callId = callId;
    _accountId = accountId;
    
    //configure ringback
    
    _ringback = [SWRingback new];
    
    [self contactChanged];
    
    //TODO: move to account to fix multiple call problem
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(returnToBackground:) name:UIApplicationWillResignActiveNotification object:nil];

    return self;
}

-(instancetype)copyWithZone:(NSZone *)zone {
    
    SWCall *call = [[SWCall allocWithZone:zone] init];
    call.contact = [self.contact copyWithZone:zone];
    call.callId = self.callId;
    call.accountId = self.accountId;
    call.callState = self.callState;
    call.mediaState = self.mediaState;
    call.inbound = self.inbound;
    call.missed = self.missed;
    call.date = [self.date copyWithZone:zone];
    call.duration = self.duration;

    return call;
}

-(instancetype)mutableCopyWithZone:(NSZone *)zone {
    
    SWMutableCall *call = [[SWMutableCall  allocWithZone:zone] init];
    call.contact = [self.contact copyWithZone:zone];
    call.callId = self.callId;
    call.accountId = self.accountId;
    call.callState = self.callState;
    call.mediaState = self.mediaState;
    call.inbound = self.inbound;
    call.missed = self.missed;
    call.date = [self.date copyWithZone:zone];
    call.duration = self.duration;

    return call;
}

+(instancetype)callWithId:(NSInteger)callId accountId:(NSInteger)accountId inBound:(BOOL)inbound {
    
    SWCall *call = [[SWCall alloc] initWithCallId:callId accountId:accountId inBound:inbound];
    
    return call;
}

-(void)createLocalNotification {
    
    _notification = [[UILocalNotification alloc] init];
    _notification.repeatInterval = 0;
    _notification.soundName = [[[SWEndpoint sharedEndpoint].ringtone.fileURL path] lastPathComponent];
    
    pj_status_t status;
    
    pjsua_call_info info;
    
    status = pjsua_call_get_info((int)self.callId, &info);
    
    if (status == PJ_TRUE) {
        _notification.alertBody = [NSString stringWithFormat:@"Incoming call from %@", self.contact.name];
    }
    
    else {
        _notification.alertBody = @"Incoming call";
    }
    
    _notification.alertAction = @"Activate app";
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] presentLocalNotificationNow:_notification];
    });
}

-(void)dealloc {

    if (_notification) {
        [[UIApplication sharedApplication] cancelLocalNotification:_notification];
    }
    
    if (_callState != SWCallStateDisconnected && _callId != PJSUA_INVALID_ID) {
        pjsua_call_hangup((int)_callId, 0, NULL, NULL);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

-(void)setCallId:(NSInteger)callId {
    
    [self willChangeValueForKey:@"callId"];
    _callId = callId;
    [self didChangeValueForKey:@"callId"];
}

-(void)setAccountId:(NSInteger)accountId {
    
    [self willChangeValueForKey:@"callId"];
    _accountId = accountId;
    [self didChangeValueForKey:@"callId"];
}

-(void)setCallState:(SWCallState)callState {
    
    [self willChangeValueForKey:@"callState"];
    _callState = callState;
    [self didChangeValueForKey:@"callState"];
}

-(void)setMediaState:(SWMediaState)mediaState {
    
    [self willChangeValueForKey:@"mediaState"];
    _mediaState = mediaState;
    [self didChangeValueForKey:@"mediaState"];
}

-(void)setRingback:(SWRingback *)ringback {
    
    [self willChangeValueForKey:@"ringback"];
    _ringback = ringback;
    [self didChangeValueForKey:@"ringback"];
}

-(void)setContact:(SWContact *)contact {
    
    [self willChangeValueForKey:@"contact"];
    _contact = contact;
    [self didChangeValueForKey:@"contact"];
}

-(void)setMissed:(BOOL)missed {
    
    [self willChangeValueForKey:@"missed"];
    _missed = missed;
    [self didChangeValueForKey:@"missed"];
}

-(void)setInbound:(BOOL)inbound {
    
    [self willChangeValueForKey:@"inbound"];
    _inbound = inbound;
    [self didChangeValueForKey:@"inbound"];
}

-(void)setDate:(NSDate *)date {
    
    [self willChangeValueForKey:@"date"];
    _date = date;
    [self didChangeValueForKey:@"date"];
}

-(void)setDuration:(NSTimeInterval)duration {
    
    [self willChangeValueForKey:@"duration"];
    _duration = duration;
    [self didChangeValueForKey:@"duration"];
}

-(void)callStateChanged {
    
    pjsua_call_info callInfo;
    pjsua_call_get_info((int)self.callId, &callInfo);
    
    switch (callInfo.state) {
        case PJSIP_INV_STATE_NULL: {
            self.callState = SWCallStateReady;
        } break;
            
        case PJSIP_INV_STATE_INCOMING: {
            [[SWEndpoint sharedEndpoint].ringtone start];
            self.callState = SWCallStateIncoming;
        } break;
            
        case PJSIP_INV_STATE_CALLING: {
            [self.ringback start]; //TODO probably not needed
            self.callState = SWCallStateCalling;
        } break;
            
        case PJSIP_INV_STATE_EARLY: {
            [self.ringback start];
            if (self.callState != SWCallStateCalling)
                self.callState = SWCallStateCalling;
        } break;
            
        case PJSIP_INV_STATE_CONNECTING: {
//            [self.ringback stop]; hangs up calling
            if (self.callState != SWCallStateConnecting)
                self.callState = SWCallStateConnecting;
            
        } break;
            
        case PJSIP_INV_STATE_CONFIRMED: {
            [self.ringback stop];
            [[SWEndpoint sharedEndpoint].ringtone stop];
            self.callState = SWCallStateConnected;
            NSString *adder;
            for (unsigned i=0;i<callInfo.media_cnt;i++) {
                if (callInfo.media[i].type == PJMEDIA_TYPE_AUDIO || callInfo.media[i].type == PJMEDIA_TYPE_VIDEO) {
                    pjsua_stream_info psi;
//                    if (pjsua_call_get_stream_info(callInfo.id, callInfo.media[i].index, &psi) == PJ_SUCCESS) {
//                        if (callInfo.media[i].type == PJMEDIA_TYPE_AUDIO) {
//                          adder=  [NSString stringWithFormat:@"%@@%dkHz %dkbit/s%u",
//                                   [Utils PjToStr :&psi.info.aud.fmt.encoding_name],
//                                    psi.info.aud.fmt.clock_rate/1000,
//                                   psi.info.aud.param->info.avg_bps/1000,
//                                   psi.info.aud.fmt.channel_cnt];
//                            
//                            
//                            
//                            if (psi.info.aud.proto==PJMEDIA_TP_PROTO_RTP_SAVP) {
//                                
//                                adder = [NSString stringWithFormat:@"%@%s", adder , "SRTP, "];
//                            }
//                            DDLogDebug(@"**************%@", adder);
//                            
//                        } else {
//                            adder=  [NSString stringWithFormat:@"%@ %dkbit/s, ",
//                                    [Utils PjToStr :&psi.info.vid.codec_info.encoding_name],
//                                     psi.info.vid.codec_param->enc_fmt.det.vid.max_bps/1000]
//                            ;
//                            DDLogDebug(@"**************%@", adder);
//                        }
//                    }
                }
            }
            
            
        } break;
            
        case PJSIP_INV_STATE_DISCONNECTED: {
            [self.ringback stop];
            [[SWEndpoint sharedEndpoint].ringtone stop];
            self.callState = SWCallStateDisconnected;
        } break;
    }
    
    [self contactChanged];
}

/* General processing for media state. "mi" is the media index */
static void on_call_generic_media_state(pjsua_call_info *ci, unsigned mi, pj_bool_t *has_error)
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
    
    PJ_LOG(4,("on_call_generic_media_state", "Call %d media %d [type=%s], status is %s",
              ci->id, mi, pjmedia_type_name(ci->media[mi].type),
              status_name[ci->media[mi].status]));
}



-(void)mediaStateChanged {
    
   
    pjsua_call_info callInfo;
    pjsua_call_get_info((int)self.callId, &callInfo);
    
    if (callInfo.media_status == PJSUA_CALL_MEDIA_ACTIVE || callInfo.media_status == PJSUA_CALL_MEDIA_REMOTE_HOLD) {
        
        pjsua_conf_connect(callInfo.conf_slot, 0);
        pjsua_conf_connect(0, callInfo.conf_slot);
    }
    
//    pjsua_call_media_status mediaStatus = callInfo.media_status;
    
    self.mediaState = (SWMediaState)callInfo.media_status;
    
}

/* Process audio media state. "mi" is the media index. */
-(void) audioStateChanged: (pjsua_call_info *)ci mi:(unsigned)mi haserror:(pj_bool_t *) haserror {

//}
//static void SWOnCallAudioState(pjsua_call_info *ci, unsigned mi,
//                               pj_bool_t *has_error)
//{
    /* Connect ports appropriately when media status is ACTIVE or REMOTE HOLD,
     * otherwise we should NOT connect the ports.
     */
    if (ci->media[mi].status == PJSUA_CALL_MEDIA_ACTIVE ||
        ci->media[mi].status == PJSUA_CALL_MEDIA_REMOTE_HOLD)
    {
        pj_bool_t connect_sound = PJ_TRUE;
        pj_bool_t disconnect_mic = PJ_FALSE;
        pjsua_conf_port_id call_conf_slot;
        
        call_conf_slot = ci->media[mi].stream.aud.conf_slot;
        
        
        /* Otherwise connect to sound device */
        if (connect_sound) {
            pjsua_conf_connect(call_conf_slot, 0);
            if (!disconnect_mic)
                pjsua_conf_connect(0, call_conf_slot);
            
            /* Automatically record conversation, if desired */
            //if (app_config.auto_rec && app_config.rec_port != PJSUA_INVALID_ID && false)
            //{
            //    pjsua_conf_connect(call_conf_slot, app_config.rec_port);
            //    pjsua_conf_connect(0, app_config.rec_port);
            //}
        }
        
        
        
    }
}


-(void)videoStateChanged: (pjsua_call_info *)ci mi:(unsigned)mi haserror:(pj_bool_t *) haserror {

    /* Process video media state. "mi" is the media index. */
    {
        if (ci->media_status != PJSUA_CALL_MEDIA_ACTIVE)
            return;

        arrange_window2(ci->media[mi].stream.vid.win_in);
        
        //    pjsua_call_vid_strm_op_param op_param;
        //    op_param.med_idx=-1;
        //    op_param.dir= PJMEDIA_DIR_ENCODING_DECODING;
        //    op_param.cap_dev= PJMEDIA_VID_DEFAULT_CAPTURE_DEV;
        //
        //    pjsua_call_set_vid_strm(ci->id,PJSUA_CALL_VID_STRM_STOP_TRANSMIT, &op_param);
        //    pjsua_call_set_vid_strm(ci->id,PJSUA_CALL_VID_STRM_START_TRANSMIT, &op_param);
        PJ_UNUSED_ARG(haserror);
    }
}

void arrange_window2(pjsua_vid_win_id wid)
{
#if PJSUA_HAS_VIDEO
    pjmedia_coord pos;
    int i, last;
    
    pos.x = 0;
    pos.y = 10;
    last = (wid == PJSUA_INVALID_ID) ? PJSUA_MAX_VID_WINS : wid;
    
    for (i=0; i<last; ++i) {
        pjsua_vid_win_info wi;
        pj_status_t status;
        
        status = pjsua_vid_win_get_info(i, &wi);
        if (status != PJ_SUCCESS)
            continue;
        
        if (wid == PJSUA_INVALID_ID)
            pjsua_vid_win_set_pos(i, &pos);
        
        if (wi.show)
            pos.y += wi.size.h;
    }
    
    if (wid != PJSUA_INVALID_ID)
        pjsua_vid_win_set_pos(wid, &pos);
    
#ifdef USE_GUI
    displayVidCallWindow(wid);
#endif

    
    
#else
    PJ_UNUSED_ARG(wid);
#endif
}



-(SWAccount *)getAccount {
    
    pjsua_call_info info;
    pjsua_call_get_info((int)self.callId, &info);
    
    return [[SWEndpoint sharedEndpoint] lookupAccount:info.acc_id];
}

-(void)contactChanged {
 
    pjsua_call_info info;
    pjsua_call_get_info((int)self.callId, &info);
    
    NSString *remoteURI = [NSString stringWithPJString:info.remote_info];
    
    self.contact = [SWUriFormatter contactFromURI:remoteURI];
}

#pragma Call Management

-(void)answer:(void(^)(NSError *error))handler {
    
    pj_status_t status;
    NSError *error;
    
    status = pjsua_call_answer((int)self.callId, PJSIP_SC_OK, NULL, NULL);
    
    if (status != PJ_SUCCESS) {
        
        error = [NSError errorWithDomain:@"Error answering up call" code:0 userInfo:nil];
    }
    
    else {
        self.missed = NO;
    }
    
    if (handler) {
        handler(error);
    }
}

-(void)hangup:(void(^)(NSError *error))handler {
    
    pj_status_t status;
    NSError *error;
    
    if (self.callId != PJSUA_INVALID_ID && self.callState != SWCallStateDisconnected) {
        
        status = pjsua_call_hangup((int)self.callId, 0, NULL, NULL);
        
        if (status != PJ_SUCCESS) {
            
            error = [NSError errorWithDomain:@"Error hanging up call" code:0 userInfo:nil];
        }
        else {
            self.missed = NO;
        }
    }
    
    if (handler) {
        handler(error);
    }
    
    self.ringback = nil;
}

//-(void)setHold:(void(^)(NSError *error))handler;
//-(void)reinvite:(void(^)(NSError *error))handler;
//-(void)transferCall:(NSString *)destination completionHandler:(void(^)(NSError *error))handler;
//-(void)replaceCall:(SWCall *)call completionHandler:(void (^)(NSError *))handler;

-(void)toggleMute:(void(^)(NSError *error))handler {

    pjsua_call_info callInfo;
    pjsua_call_get_info((int)self.callId, &callInfo);
    
    if (!self.mute) {
        pjsua_conf_disconnect(0, callInfo.conf_slot);
        self.mute = YES;
    }
    
    else {
        pjsua_conf_connect(0, callInfo.conf_slot);
        self.mute = NO;
    }
}

-(void)toggleSpeaker:(void(^)(NSError *error))handler {
    
    if (!self.speaker) {
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        self.speaker = YES;
    }
    
    else {
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
        self.speaker = NO;
    }
}

-(void)sendDTMF:(NSString *)dtmf handler:(void(^)(NSError *error))handler {
    
    pj_status_t status;
    NSError *error;
    pj_str_t digits = [dtmf pjString];
    
    status = pjsua_call_dial_dtmf((int)self.callId, &digits);

    if (status != PJ_SUCCESS) {
        error = [NSError errorWithDomain:@"Error sending DTMF" code:0 userInfo:nil];
    }
    
    if (handler) {
        handler(error);
    }
}

#pragma Application Methods

-(void)returnToBackground:(NSNotificationCenter *)notification {
    
    if (self.callState == SWCallStateIncoming) {
        [self createLocalNotification];
    }
}



@end

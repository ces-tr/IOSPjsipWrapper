//
//  SWEndpointConfiguration.h
//  swig
//
//  Created by Pierre-Marc Airoldi on 2014-08-20.
//  Copyright (c) 2014 PeteAppDesigns. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <pjsip/sip_util.h>
#import <pjsua.h>

#ifndef kSWMaxCalls
#   define kSWMaxCalls  100
#endif
//#define kSWMaxCalls 30
#ifndef kSWLogLevel
#   define kSWLogLevel 5
#endif
#ifndef kSWLogConsoleLevel
#   define kSWLogConsoleLevel 4
#endif
#ifndef kSWLogFilename
#define kSWLogFilename nil
#endif
#ifndef kSWLogFileFlags
#define kSWLogFileFlags PJ_O_APPEND
#endif
#ifndef kSWClockRate
#define kSWClockRate 16000
#endif
#ifndef kSWSndClockRate
#define kSWSndClockRate 0
#endif
#ifndef SWECNO_LIMIT_DURATION
#define SWECNO_LIMIT_DURATION	(int)0x7FFFFFFF
#endif
#ifndef SWEC_MAX_AVI
#define SWEC_MAX_AVI		4
#endif
#ifndef SWEC_NO_NB
#define SWEC_NO_NB			-2
#endif



@interface SWEndpointConfiguration : NSObject

//ua config
@property (nonatomic) NSUInteger maxCalls; //4 is default

//log config
@property (nonatomic) NSUInteger logLevel; //5 is default
@property (nonatomic) NSUInteger logConsoleLevel; //4 is default
@property (nonatomic, strong) NSString *logFilename; //nil by default
@property (nonatomic) NSUInteger logFileFlags; //append by default

//audio config
@property (nonatomic) NSUInteger clockRate; //16kHZ is default
@property (nonatomic) NSUInteger sndClockRate; //0 is default

@property (nonatomic) NSUInteger aud_cnt;
@property (nonatomic) NSUInteger redir_op;// = PJSIP_REDIRECT_ACCEPT_REPLACE;
@property (nonatomic) NSUInteger duration;// = PJSUA_APP_NO_LIMIT_DURATION;
@property (nonatomic) NSUInteger wav_id;// = PJSUA_INVALID_ID;
@property (nonatomic) NSUInteger rec_id;// = PJSUA_INVALID_ID;
@property (nonatomic) NSUInteger wav_port;// = PJSUA_INVALID_ID;
@property (nonatomic) NSUInteger rec_port;// = PJSUA_INVALID_ID;
@property (nonatomic) NSUInteger mic_level;// = cfg->speaker_level = 1.0;
@property (nonatomic) NSUInteger speaker_level;
@property (nonatomic) NSUInteger capture_dev;// = PJSUA_INVALID_ID;
@property (nonatomic) NSUInteger playback_dev;// = PJSUA_INVALID_ID;
@property (nonatomic) NSUInteger capture_lat;// = PJMEDIA_SND_DEFAULT_REC_LATENCY;
@property (nonatomic) NSUInteger playback_lat;// = PJMEDIA_SND_DEFAULT_PLAY_LATENCY;
@property (nonatomic) NSUInteger ringback_slot;// = PJSUA_INVALID_ID;
@property (nonatomic) NSUInteger ring_slot;// = PJSUA_INVALID_ID;

//video config
@property (nonatomic) NSUInteger vid_cnt;
@property (nonatomic) NSUInteger vcapture_dev;
@property (nonatomic) NSUInteger vrender_dev;
@property (nonatomic) Boolean in_auto_show;
@property (nonatomic) Boolean out_auto_transmit;
@property (nonatomic) NSUInteger avi_def_idx;
@property (nonatomic) Boolean avi_auto_play;

//transport configurations
@property (nonatomic, strong) NSArray *transportConfigurations; //empty by default must specify
@property (nonatomic) Boolean no_udp;
@property (nonatomic) Boolean no_tcp;

@property (nonatomic) pjsua_transport_config rtp_cfg;


+(instancetype)configurationWithTransportConfigurations:(NSArray *)transportConfigurations;

@end

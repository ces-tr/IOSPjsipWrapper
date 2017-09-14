//
//  SWCall.h
//  swig
//
//  Created by Pierre-Marc Airoldi on 2014-08-21.
//  Copyright (c) 2014 PeteAppDesigns. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SWCallProtocol.h"
#import "pjsua.h"
#import "SWRingback.h"
#import "SWRingtone.h"
#import "SWContact.h"

//TODO: move to 2 sublclasses (incoming/outgoing)

@class SWAccount;

typedef NS_ENUM(NSInteger, SWCallState) {
    SWCallStateReady,
    SWCallStateIncoming,
    SWCallStateCalling,
    SWCallStateConnecting,
    SWCallStateConnected,
    SWCallStateDisconnected
};

typedef NS_ENUM(NSInteger, SWMediaState) {
    SWMediaStateNone = PJSUA_CALL_MEDIA_NONE,
    SWMediaStateError = PJSUA_CALL_MEDIA_ERROR,
    SWMediaStateActive = PJSUA_CALL_MEDIA_ACTIVE,
    SWMediaStateLocalHold = PJSUA_CALL_MEDIA_LOCAL_HOLD,
    SWMediaStateRemoteHole = PJSUA_CALL_MEDIA_REMOTE_HOLD
};

@interface SWCall : NSObject <SWCallProtocol, NSCopying, NSMutableCopying>

@property (nonatomic, readonly, strong) SWContact *contact;
@property (nonatomic, readonly) NSInteger callId;
@property (nonatomic, readonly) NSInteger accountId;
@property (nonatomic, readonly) SWCallState callState;
@property (nonatomic, readonly) SWMediaState mediaState;
@property (nonatomic, readonly) BOOL inbound;
@property (nonatomic, readonly) BOOL missed;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSTimeInterval duration; //TODO: update with timer

-(instancetype)initWithCallId:(NSUInteger)callId accountId:(NSInteger)accountId inBound:(BOOL)inbound;
+(instancetype)callWithId:(NSInteger)callId accountId:(NSInteger)accountId inBound:(BOOL)inbound;

-(SWAccount *)getAccount;

-(void)answer:(void(^)(NSError *error))handler;
-(void)hangup:(void(^)(NSError *error))handler;

//-(void)setHold:(void(^)(NSError *error))handler;
//-(void)reinvite:(void(^)(NSError *error))handler;
//-(void)transferCall:(NSString *)destination completionHandler:(void(^)(NSError *error))handler;
//-(void)replaceCall:(SWCall *)call completionHandler:(void (^)(NSError *))handler;

-(void)toggleMute:(void(^)(NSError *error))handler;
-(void)toggleSpeaker:(void(^)(NSError *error))handler;
-(void)sendDTMF:(NSString *)dtmf handler:(void(^)(NSError *error))handler;


 extern void displayVidCallWindow(pjsua_vid_win_id wid);

@end

//
//  SWCallProtocol.h
//  Pods
//
//  Created by Pierre-Marc Airoldi on 2014-09-02.
//
//

#import <Foundation/Foundation.h>
#import "pjsua.h"

@protocol SWCallProtocol <NSObject>

-(void)callStateChanged;
-(void)mediaStateChanged;
-(void)audioStateChanged: (pjsua_call_info *)ci mi:(unsigned)mi haserror:(pj_bool_t *) haserror;
-(void)videoStateChanged: (pjsua_call_info *)ci mi:(unsigned)mi haserror:(pj_bool_t *) haserror;;

@end

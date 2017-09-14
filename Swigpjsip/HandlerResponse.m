//
//  HandlerResponse.m
//  ipjsua
//
//  Created by MacBook  on 9/8/17.
//  Copyright © 2017 CesTR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HandlerResponse.h"

@implementation SWHandlerResponse

-(instancetype)init {
    
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    _pjStatus= -1;
    _pjError= nil;
    
    return self;
}
@end

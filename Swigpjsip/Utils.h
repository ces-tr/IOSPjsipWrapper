//
//  Utils.h
//  ipjsua
//
//  Created by MacBook  on 9/11/17.
//  Copyright © 2017 CesTR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pj/types.h>

@interface Utils : NSObject

+(void) listPjsuaCodecs;
+(NSString*) PjToStr :  (const pj_str_t*) str;

@end

//
//  Utils.m
//  ipjsua
//
//  Created by MacBook  on 9/11/17.
//  Copyright © 2017 CesTR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utils.h"
#import "pjsua.h"

@implementation Utils

+(void) listPjsuaCodecs {
    
    //Debug List Of Codecs
    pjsua_codec_info c[32];
    unsigned k,i, count = PJ_ARRAY_SIZE(c);
    printf("List of audio codecs:\n");
//    pj_str_t codec_s;
    //    pjsua_codec_set_priority(pj_cstr(&codec_s, "PCMU/8000/1"), PJMEDIA_CODEC_PRIO_HIGHEST);
    
    pjsua_enum_codecs(c, &count);
    
    for (k=0; k<count; ++k) {
        
        printf("  %d\t%.*s\n", c[k].priority, (int)c[k].codec_id.slen,
               
               c[k].codec_id.ptr);
        
    }
    puts("");
    printf("List of video codecs:\n");
    pjsua_vid_enum_codecs(c, &count);
    for (i=0; i<count; ++i) {
        printf("  %d\t%.*s%s%.*s\n", c[i].priority,
               (int)c[i].codec_id.slen,
               c[i].codec_id.ptr,
               c[i].desc.slen? " - ":"",
               (int)c[i].desc.slen,
               c[i].desc.ptr);
    }
}

+(NSString*) PjToStr :  (const pj_str_t*) str
{
    NSString *rab;
    //rab.Format("%.*s", str->slen, str->ptr);
    rab=  [NSString stringWithFormat:@"%.*s", (int)str->slen,str->ptr];
    return rab;
}


@end

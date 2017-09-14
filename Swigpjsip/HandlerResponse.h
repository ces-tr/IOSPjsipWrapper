//
//  HandlerResponse.h
//  ipjsua
//
//  Created by MacBook  on 9/8/17.
//  Copyright © 2017 CesTR. All rights reserved.
//

@interface SWHandlerResponse : NSObject

//ua config
@property (nonatomic) NSInteger pjStatus; //0 is SUCCESS
@property (nonatomic) NSError* pjError; //nil

@end


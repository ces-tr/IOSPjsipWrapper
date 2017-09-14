//
//  SWViewController.m
//  Swig
//
//  Created by Pierre-Marc Airoldi on 09/01/2014.
//  Copyright (c) 2014 Pierre-Marc Airoldi. All rights reserved.
//

#import "SWViewController.h"
#import "Swig.h"
#import "IOSPjsipWrapper.h"

@interface SWViewController ()


@end

@implementation SWViewController

@synthesize txtaddress,txtusername,txtpswd,txtProxy,txtdomain;

id cself;


- (void)viewDidLoad
{
    [super viewDidLoad];
    cself =self;
    
}

-(void)viewWillAppear:(BOOL)animated
{
 
    txtaddress.text= @"iospjsip@cestr.onsip.com";
    txtdomain.text= @"cestr.onsip.com";
    txtusername.text=@"cestr_cesar_turrubiates";
    txtpswd.text=@"4Kg7KFmpMY54njJR";
    txtProxy.text=@"sip.onsip.com";
    
    txtaddress.enabled= txtaddress.enabled=txtusername.enabled=txtpswd.enabled= txtProxy.enabled=  NO;
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)txtproxyEditBegin:(id)sender {
    
}

-(IBAction)makeCall:(id)sender {
 
    
    IOSPjsipWrapper *iOSPjsipWrapper = [IOSPjsipWrapper iOSPjsipWrapperInstance];
    [iOSPjsipWrapper makeCall];
    
    
//    SWAccount *account = [[SWEndpoint sharedEndpoint] firstAccount];
//
//    [account makeCall:@"cesar@cestr.onsip.com" completionHandler:^(NSError *error) {
//      
//        if (error) {
//            NSLog(@"%@",[error description]);
//        }
//    }];
    
    
//    make_single_call(NULL);
}

//static pj_status_t make_single_call(pj_cli_cmd_val *cval)
//{
//    struct input_result result;
//    char dest[64] = {"sip:cesar@cestr.onsip.com"};
//    char out_str[128];
//    
//    
//    pj_str_t tmp = pj_str(dest);
//    
//    //    pj_strncpy_with_null(&tmp, &cval->argv[1], sizeof(dest));
//    
//    pj_ansi_snprintf(out_str,
//                     sizeof(out_str),
//                     "(You currently have %d calls)\n",
//                     pjsua_call_get_count());
//    
//    //    pj_cli_sess_write_msg(cval->sess, out_str, pj_ansi_strlen(out_str));
//    
//   
//    
////    pjsua_msg_data_init(&msg_data);
//    TEST_MULTIPART(&msg_data);
////    call_opt.vid_cnt=0;
//    
//    pjsua_acc_id acc_ids[16];
//    unsigned count = PJ_ARRAY_SIZE(acc_ids);
//    int i;
//    
//    printf(">>>>\n");
//    
//    pjsua_enum_accs(acc_ids, &count);
//    
//    pjsua_call_id callIdentifier;
//    pj_status_t status;
//
//    status =pjsua_call_make_call(accID, &tmp, &call_opt, NULL,
//                                 NULL, &callIdentifier);
//    
//    
//    return PJ_SUCCESS;
//}
-(instancetype)init {
    
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    [self intitializeView];
    
    return self;
}

-(void) intitializeView{
//    SWAccountConfiguration *configuration = [SWAccountConfiguration new];
//    configuration.username = @"cestr_cesar_turrubiates";
//    configuration.password = @"4Kg7KFmpMY54njJR";
//    configuration.domain = @"cestr.onsip.com";
//    configuration.address = [SWAccountConfiguration addressFromUsername:@"iospjsip" domain:configuration.domain];
//    configuration.proxy = @"sip.onsip.com";
//    configuration.registerOnAdd = YES;
    
}

- (IBAction)makeVideoCall:(id)sender {
    
    IOSPjsipWrapper *iOSPjsipWrapper = [IOSPjsipWrapper iOSPjsipWrapperInstance];
    [iOSPjsipWrapper makeVideoCall];
}

-(IBAction)answer:(id)sender {
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] firstAccount];

    SWCall *call = [account firstCall];
    
    if (call) {
        [call answer:^(NSError *error) {
            
        }];
    }
}

-(IBAction)mute:(id)sender {
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] firstAccount];
    
    SWCall *call = [account firstCall];

    if (call) {
        
        [call toggleMute:^(NSError *error) {

        }];
    }
}


-(IBAction)speaker:(id)sender {
    
    SWAccount *account = [[SWEndpoint sharedEndpoint] firstAccount];
    
    SWCall *call = [account firstCall];
    
    if (call) {
        
        [call toggleSpeaker:^(NSError *error) {

        }];
    }
}

void displayVidCallWindow(pjsua_vid_win_id wid)
{
#if PJSUA_HAS_VIDEO
    int i, last;
    
    i = (wid == PJSUA_INVALID_ID) ? 0 : wid;
    last = (wid == PJSUA_INVALID_ID) ? PJSUA_MAX_VID_WINS : wid+1;
    
    for (;i < last; ++i) {
        pjsua_vid_win_info wi;
        
        if (pjsua_vid_win_get_info(i, &wi) == PJ_SUCCESS) {
            UIView *parent = [cself view ] ;//app.viewController.view;
            UIView *view = (__bridge UIView *)wi.hwnd.info.ios.window;
            
            if (view) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    /* Add the video window as subview */
                    if (![view isDescendantOfView:parent])
                        [parent addSubview:view];
                    
                    if (!wi.is_native) {
                        /* Resize it to fit width */
                        view.bounds = CGRectMake(0, 0, parent.bounds.size.width,
                                                 (parent.bounds.size.height *
                                                  1.0*parent.bounds.size.width/
                                                  view.bounds.size.width));
                        /* Center it horizontally */
                        view.center = CGPointMake(parent.bounds.size.width/2.0,
                                                  view.bounds.size.height/2.0);
                    } else {
                        /* Preview window, move it to the bottom */
                        view.center = CGPointMake(parent.bounds.size.width/2.0,
                                                  parent.bounds.size.height-
                                                  view.bounds.size.height/2.0);
                    }
                });
            }
        }
    }
    
    
#endif
}

@end

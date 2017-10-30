//
//  SWAppDelegate.m
//  Swig
//
//  Created by CocoaPods on 09/01/2014.
//  Copyright (c) 2014 Pierre-Marc Airoldi. All rights reserved.
//

//#import <pjlib.h>
//#import <pjsua.h>
//#import <pj/log.h>
//#import "Swig.h"

//#include "../../pjsua_app.h"
//#include "../../pjsua_app_common.h"
//#include "../../pjsua_app_config.h"

#import "SWAppDelegate.h"
#import "IOSPjsipWrapper.h"


IOSPjsipWrapper *iOSPjsipWrapper;


@implementation SWAppDelegate

#define THIS_FILE	"SWAppDelegate"

#define KEEP_ALIVE_INTERVAL 600

//SWAppDelegate      *app;
//static pjsua_app_cfg_t  app_cfg;
//static bool             isShuttingDown;
//static char           **restartArgv;
//static int              restartArgc;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    iOSPjsipWrapper = [IOSPjsipWrapper iOSPjsipWrapperInstance];
    
    SWAccountConfiguration *accountConfig = [SWAccountConfiguration new];
    
    accountConfig.address= @"iospjsip@cestr.onsip.com";
    accountConfig.domain= @"cestr.onsip.com";
    accountConfig.username= @"cestr_cesar_turrubiates";
    accountConfig.password= @"4Kg7KFmpMY54njJR";
    accountConfig.proxy = @"sip.onsip.com";
    accountConfig.registerOnAdd = YES;

    
    [iOSPjsipWrapper performSelector:@selector(configureEndpoint)] ;
    
//    SEL aSelector = NSSelectorFromString(@"addSIPAccountP:completionHandler:");
    
    [iOSPjsipWrapper performSelector:@selector(addSIPAccountP:completionHandler:) withObject:accountConfig withObject: ^(SWHandlerResponse *error) {
        
            if (error) {
                NSLog(@"%@",[error description]);
            }
    } ] ;
    


    
//    [iOSPjsipWrapper configureEndpoint];
//    [iOSPjsipWrapper addSIPAccount];

    //[iOSPjsipWrapper release];
    
    /* Start pjsua app thread */
    
//   
//    BOOL var= [self Initpjsua];
//    if(var)
//        [self addAccount];


    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


/*
- (BOOL)Initpjsua
{
    // TODO: read from config?
    const char **argv = pjsua_app_def_argv;
    int argc = PJ_ARRAY_SIZE(pjsua_app_def_argv) -1;
    pj_status_t status;
    
    isShuttingDown = false;
//    displayMsg("Starting..");
    pj_log_set_level( 4 );
    pj_bzero(&app_cfg, sizeof(app_cfg));
    if (restartArgc) {
        app_cfg.argc = restartArgc;
        app_cfg.argv = restartArgv;
    } else {
        app_cfg.argc = argc;
        app_cfg.argv = (char**)argv;
    }
//    app_cfg.on_started = &pjsuaOnStartedCb;
//    app_cfg.on_stopped = &pjsuaOnStoppedCb;
//    app_cfg.on_config_init = &pjsuaOnAppConfigCb;
    
    status = pjsua_app_init(&app_cfg);
    if (status != PJ_SUCCESS) {
        char errmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, errmsg, sizeof(errmsg));
//            displayMsg(errmsg);
        pjsua_app_destroy();
        return false;
    }
    
    status = pjsua_app_run(PJ_FALSE);
    if (status != PJ_SUCCESS) {
        char errmsg[PJ_ERR_MSG_SIZE];
        pj_strerror(status, errmsg, sizeof(errmsg));
//        displayMsg(errmsg);
        return false;
    }

    
    return true;
    
}

-(void) addAccount {
//    pj_cli_cmd_val *account = NULL;
    pj_cli_cmd_val account[1] = {{ 0, 0, 0, 0 }};
    
    account-> argv[0]=pj_str("a");
    account-> argv[1]= pj_str("sip:iospjsip@cestr.onsip.com");
    account-> argv[2]= pj_str("sip:cestr.onsip.com");
    account-> argv[3]= pj_str("*");
    account-> argv[4]= pj_str("cestr_cesar_turrubiates");
    account-> argv[5]= pj_str("4Kg7KFmpMY54njJR");
    
    cmd_add_account(account);

}

//* Add account
static pj_status_t cmd_add_account(pj_cli_cmd_val *cval)
{
    pjsua_acc_config acc_cfg;
    pj_status_t status;
    
    pjsua_acc_config_default(&acc_cfg);
    acc_cfg.id = cval->argv[1];
    acc_cfg.reg_uri = cval->argv[2];
    acc_cfg.cred_count = 1;
    acc_cfg.cred_info[0].scheme = pj_str("Digest");
    acc_cfg.cred_info[0].realm = cval->argv[3];
    acc_cfg.cred_info[0].username = cval->argv[4];
    acc_cfg.cred_info[0].data_type = 0;
    acc_cfg.cred_info[0].data = cval->argv[5];
    
    acc_cfg.proxy_cnt = 1;
    acc_cfg.proxy[0] = pj_str("sip:sip.onsip.com");
    
    acc_cfg.rtp_cfg = app_config.rtp_cfg;
    app_config_init_video(&acc_cfg);
    
//    pjsua_acc_id accountId = 0;
//    accID=accountId;
    status = pjsua_acc_add(&acc_cfg, PJ_TRUE, &accID);
    if (status != PJ_SUCCESS) {
        pjsua_perror(THIS_FILE, "Error adding new account", status);
    }
    
    return status;
}
 */






@end

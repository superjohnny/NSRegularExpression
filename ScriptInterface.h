//
//  ScriptInterface.h
//  digitalforms
//
//  Created by Adrian Herridge on 05/08/2011.
//  Copyright 2011 Compsoft plc. All rights reserved.
//

#ifndef __SCRIPTIF
#define __SCRIPTIF

#import <Foundation/Foundation.h>
#include "lua.h"
#include "lapi.h"
#include "lualib.h"
#include "ldebug.h"
#include "lauxlib.h"


@interface CScriptInterface : NSObject {
    lua_State*          scriptEngine;
    BOOL                initialised;
    NSMutableArray*     scripts;
}

- (id)init:(BOOL)staticInstance;
+ (int)staticExecute:(NSString *)code forEvent:(NSString*)eventName;
+ (void)debugTimerTick;
- (void)executeRaw:(NSString*)script;
- (int)execute:(NSString*)script eventName:(NSString*)eventName silent:(BOOL)silent;
- (void)stopEngine;
- (void)triggerEvent:(NSString*)eventName object:(NSString*)object;
- (void)registerFunctionsFromStatic:(BOOL)staticInstance;

@end

#endif
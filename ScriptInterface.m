//
//  ScriptInterface.m
//  digitalforms
//
//  Created by Adrian Herridge on 05/08/2011.
//  Copyright 2011 Compsoft plc. All rights reserved.
//


/***************************************************************************
 ***
 ***    The script engine is lua based, hosted within a objective c class
 ***    comprised entirely using static methods.
 ***    
 ***    The class will maintain a dictionary of all the objects and represent
 ***    them within the engine using object dot notaion.
 ***    
 ***    when methods are called 
 ***
 ***************************************************************************/

#import "ScriptInterface.h"

#import "TFForm.h"
#import "TFPage.h"
#import "TFRow.h"
#import "TFGroup.h"
#import "TFTextArea.h"
#import "TFTextField.h"
#import "TFCheckbox.h"
#import "TFSelect.h"
#import "TFMultiSelect.h"
#import "TFImage.h"
#import "TFPhoto.h"
#import "TFActionView.h"
#import "TFSignature.h"
#import "TFSketch.h"
#import "TFDate.h"
#import "TFTime.h"
#import "TFLabel.h"
#import "TFButton.h"
#import "TFLine.h"
#import "TFScriptErrorViewController.h"
#import "TFScriptWaitMessage.h"
#import "TFLocalisedDate.h"

@implementation CScriptInterface

static NSTimer*     debugTimer;
static lua_State*   debugState;

+ (void)debugTimerTick {
    
    if ([APP_DELEGATE isDebugging]) {
        
        /* we are currently debugging, so we need to call a resume on the suspended thread */
        if ([APP_DELEGATE debugStep] > 0) {
            
            [APP_DELEGATE setDebugStep:[APP_DELEGATE debugStep] -1];
            int status = lua_resume(debugState, 0);
            if (status == LUA_YIELD) {
                /* nothing to do */
            } else {
                if (status == LUA_ERRRUN && lua_isstring(debugState, -1)) {
                    
                    /* there was an error, error is pushed onto the stack and the position is re-pushed in front */
                    const char* errMessage = lua_tostring(debugState, -1);
                    NSString* errorMsg = [NSString stringWithUTF8String:errMessage];

                    lua_pop(debugState, -1); // pop the error to avoid destabalising the stack
                    
                    // ]:$:
                    
                    NSString* errLine = [errorMsg substringFromIndex:[errorMsg rangeOfString:@"]:"].location + 2];
                    errLine = [errLine substringToIndex:[errLine rangeOfString:@":"].location];
                    
                    errorMsg = [errorMsg substringFromIndex:[errorMsg rangeOfString:@"]:"].location + 2];
                    errorMsg = [errorMsg substringFromIndex:[errorMsg rangeOfString:@":"].location + 1];
                    
                    TFScriptErrorViewController* d = [[TFScriptErrorViewController alloc] initWithNibName:@"TFScriptErrorViewController" bundle:nil];
                    [d setCode:[APP_DELEGATE debugStartedFromThisEvent] forEvent:@"debugger.code.stepLine()" currentLine:[APP_DELEGATE debugLastLine] withErrorDescription:errorMsg];
                    
                    [APP_DELEGATE setIsDebugging:NO];
                    [APP_DELEGATE setDebugStep:0];
                    if (debugTimer) {
                        [debugTimer invalidate];
                        debugTimer = nil;
                    }
                    
                    /* if debugging dialog present the poop-can the dialog ready to push a new one */
                    UIViewController* vc = (UIViewController*)[[APP_DELEGATE m_mainController] overlayViewController];
                    if ([vc isKindOfClass:[TFScriptDebugger class]]) {
                        [[APP_DELEGATE m_mainController] popOverlay];
                    }
                    
                    [[APP_DELEGATE m_mainController] pushOverlay:d];
                    
                    
                }
            }
        }
        
    } else {
        
        if ([APP_DELEGATE scriptDebugDialog]) {
            if ([[[APP_DELEGATE m_mainController] overlayViewController] isEqual:[APP_DELEGATE scriptDebugDialog]]) {
                [[APP_DELEGATE m_mainController] popOverlay];
            }
        }
        
        if (debugTimer) {
            [debugTimer invalidate];
            debugTimer = nil;
            debugState = nil;
        }

    }
    
}

-(id)init:(BOOL)staticInstance {
    
    /* sets up the environment for the first static call */
    
    self = [super init];
    
    if (!scriptEngine) {
        scriptEngine = (lua_State*)lua_open();
        initialised = YES;
    }
    
    [self registerFunctionsFromStatic:staticInstance];
    
    return self;
    
}


- (void)stopEngine {
    
    /* revoke the lua engine */
    lua_close(scriptEngine);
    scriptEngine = nil;
    if (debugTimer) {
        [debugTimer invalidate];
    }
}

#pragma mark 'C' style lua interface functions for registration

// GUI OBJECT FUNCTIONS

static int scriptNullFunction(lua_State* L) {
    return 0;
}

static int scriptHandlePropertyGet(lua_State* L) {
    
    /* setup the stack vars */
    NSString* key = [NSString stringWithUTF8String:lua_tostring(L, 2)];
    int mem = (int)lua_tonumber(L, 1);
    NSObject* value = nil;
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)mem;
    if (o && [o isKindOfClass:[TFBaseObjectController class]]) {
        
        if ([key isEqualToString:@"value"]) {
            
            value = [((TFBaseObjectController*)o) getValueInEntity];
            
            /* to make things more logical for users to understand we are removing the pushing of nil and instead returning false, "", 0 */
            
            if(!value || [value isKindOfClass:[NSNull class]])
            {
                if ([o isKindOfClass:[TFCheckbox class]]) {
                    lua_pushboolean(L, 0);
                    return 1;
                } else {
                    lua_pushstring(L, "\0");
                    return 1;
                }
            }
            
        }
        
        if ([key isEqualToString:@"title"]) {
            if ([((TFBaseObjectController*)o) objectLabel]) {
                value = [[((TFBaseObjectController*)o) objectLabel] text];
            } else {
                value = [((TFBaseObjectController*)o) getStringProperty:TF_PROPERTY_TITLE];
            }
        }
        
        if ([key isEqualToString:@"name"]) {
            value = [((TFBaseObjectController*)o) getStringProperty:TF_PROPERTY_DATATITLE];
        }
        
        if ([key isEqualToString:@"visible"]) {
            value = [NSNumber numberWithBool:![((TFBaseObjectController*)o) objectHidden]];
        }
        
        if ([key isEqualToString:@"enabled"]) {
            value = [NSNumber numberWithBool:![((TFBaseObjectController*)o) objectDisabled]];
        }
        
        if ([key isEqualToString:@"valid"]) {
            value = [NSNumber numberWithBool:[((TFBaseObjectController*)o) dataValid]];
        }
        
        if ([key isEqualToString:@"description"]) {
            if ([((TFBaseObjectController*)o) isKindOfClass:[TFSelect class]]) {
                value = [((TFSelect*)o) getDescriptionCurrentItem];
            }
        }
        
        if ([key isEqualToString:@"message"]) {
            if ([((TFBaseObjectController*)o) message]) {
                value = [((TFBaseObjectController*)o) message];
            } else {
                value = @"";
            }
            
        }
        
        /* this could also be a call to a function which exists in the obj-object */
        if (!value) {
            
            NSDictionary* scripts = (NSDictionary*)[((TFBaseObjectController*)o) getObjectProperty:TF_PROPERTY_SCRIPTS];
            if ([scripts objectForKey:key] != nil) {
                /* exists not to add this ref and call it on the interface */
                [[((TFBaseObjectController*)o) getScriptEngine] execute:[NSString stringWithFormat:@"local this = %@; \n\n %@",[((TFBaseObjectController*)o) getStringProperty:TF_PROPERTY_FIELDNAME],[scripts objectForKey:key]]  eventName:[NSString stringWithFormat:@"%@.%@", [((TFBaseObjectController*)o) getObjectProperty:TF_PROPERTY_FIELDNAME], key] silent:NO];
            }
            
            /* now push an empty function back as a result */
            lua_pushcfunction(L, scriptNullFunction);
            return 1;
            
        }
    }
    
    if (!value || [value isKindOfClass:[NSNull class]]) {
        
        lua_pushnil(L);
        return 1;
        
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        lua_pushstring(L, [((NSString*)value) UTF8String]);
        return 1;
    }
    
    if ([value isKindOfClass:[NSNumber class]]) {
        
        if (strcmp([((NSNumber*)value) objCType], @encode(BOOL)) == 0) {
            lua_pushboolean(L, (int)[((NSNumber*)value) boolValue]);
        }
        else {
            lua_pushnumber(L, [((NSNumber*)value) doubleValue]);
        }
        return 1;
    }
    
    if ([value isKindOfClass:[UIImage class]]) {
        lua_pushstring(L, [[((UIImage*)value) base64Value] UTF8String]);
        return 1;
    }
    
    return 0;
    
}

static int scriptHandlePropertyChange(lua_State* L) {
    
    /* setup the stack vars */
    NSString* key = [NSString stringWithUTF8String:lua_tostring(L, 2)];
    int mem = (int)lua_tonumber(L, 1);
    NSObject* value = nil;
    
    /* pull out the value and turn into objc */
    
    BOOL canBeBothTextAndNumber = NO;
    
    if (lua_isnumber(L, 3)) {
        value = [NSNumber numberWithDouble:lua_tonumber(L, 3)];
    } else if (lua_isboolean(L, 3)) {
        value = [NSNumber numberWithBool:(BOOL)lua_toboolean(L, 3)];
    } else if (lua_isstring(L, 3)) {
        value = [NSString stringWithUTF8String:lua_tostring(L, 3)];
    }
    
    if (lua_isnumber(L, 3) && lua_isstring(L, 3)) {
        canBeBothTextAndNumber = YES;
    }
    
    if (value) {
        /* get the object */
        
        NSObject* o = (__bridge NSObject*)(void*)(unsigned int)mem;
        
        /* now switch on the key that has been assigned */
        
        if ([key isEqualToString:@"value"]) {
            
            if ([o isKindOfClass:[TFDate class]]) {
                TFDate* ob = (TFDate*)o;
                if (canBeBothTextAndNumber) {
                    value = [NSString stringWithUTF8String:lua_tostring(L, 3)];
                }
                [ob setValue:(NSString*)value];
            }
            
            if ([o isKindOfClass:[TFCheckbox class]]) {
                TFCheckbox* ob = (TFCheckbox*)o;
                [ob setValue:[((NSNumber*)value) boolValue]];
            }
            
            if ([o isKindOfClass:[TFMultiSelect class]]) {
                
            }
            
            if ([o isKindOfClass:[TFTextArea class]]) {
                TFTextArea* ob = (TFTextArea*)o;
                if (canBeBothTextAndNumber) {
                    value = [NSString stringWithUTF8String:lua_tostring(L, 3)];
                }
                [ob setValue:(NSString*)value];
            }
            
            if ([o isKindOfClass:[TFTextField class]]) {
                TFTextField* ob = (TFTextField*)o;
                if ([value isKindOfClass:[NSString class]]) {
                    [ob setValue:(NSString*)value];
                }
                if ([value isKindOfClass:[NSNumber class]]) {
                    NSObject* dp = [ob getObjectProperty:TF_PROPERTY_DECIMALPLACES];
                    if ([dp isKindOfClass:[NSNumber class]]) {
                        NSString* formatString = [NSString stringWithFormat:@"%%.%if", [((NSNumber*)dp) intValue]];
                        [ob setValue:[NSString stringWithFormat:formatString,[((NSNumber*)value) doubleValue]]];
                    } else {
                        [ob setValue:[NSString stringWithFormat:@"%@",value]];
                    }
                    
                }
            }
            
            if ([o isKindOfClass:[TFTime class]]) {
                TFTime* ob = (TFTime*)o;
                if (canBeBothTextAndNumber) {
                    value = [NSString stringWithUTF8String:lua_tostring(L, 3)];
                }
                [ob setValue:(NSString*)value];
            }
            
        }
        
        if ([key isEqualToString:@"title"]) {
            
            if (canBeBothTextAndNumber) {
                value = [NSString stringWithUTF8String:lua_tostring(L, 3)];
            }
            
            if ([((TFBaseObjectController*)o) objectLabel]) {
                [[((TFBaseObjectController*)o) objectLabel] setText:(NSString*)value];
                
                /* resize the label because it may be too small for the new text */
                UILabel* l = [((TFBaseObjectController*)o) objectLabel];
                if (l) {
                    CGRect r = l.frame;
                    UIFont* f = l.font;
                    NSString* t = l.text;
                    r.size = [t sizeWithFont:f];
                    l.frame = r;
                }
                
            } else if ([((TFBaseObjectController*)o) isKindOfClass:[TFButton class]]) {
                
                TFButton* b = (TFButton*)((TFBaseObjectController*)o);
                [b setButtonTitle:(NSString*)value];
                
            }
            
        }
        
        
        if ([key isEqualToString:@"enabled"]) {
            
            if ([o respondsToSelector:@selector(disableObject:)]) {
                [o performSelector:@selector(disableObject:) withObject:[NSNumber numberWithBool:![((NSNumber*)value) boolValue]]];
            }
            
        }
        
        if ([key isEqualToString:@"visible"]) {
            
            if ([o respondsToSelector:@selector(hideObject:)]) {
                [o performSelector:@selector(hideObject:) withObject:[NSNumber numberWithBool:![((NSNumber*)value) boolValue]]];
            }
            
        }
        
        if ([key isEqualToString:@"valid"]) {
            
            [((TFBaseObjectController*)o) setDataValid:[((NSNumber*)value) boolValue]];
            
        }
        
        if ([key isEqualToString:@"message"]) {
            
            if (canBeBothTextAndNumber) {
                value = [NSString stringWithUTF8String:lua_tostring(L, 3)];
            }
            
            [((TFBaseObjectController*)o) setMessage:(NSString*)value];
            
        }
    }

    return 0;
}

// SUBMISSION

static int scriptSubmitData(lua_State* L) {
    [[[APP_DELEGATE m_mainController] currentTFForm] validateForm];
    return 0;
}

static int scriptAlertMessage(lua_State* L) {
    
    NSString* title = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    NSString* body = [NSString stringWithUTF8String:lua_tostring(L, 2)];
    
    TFActionView* av = [[TFActionView alloc] initWithNibName:@"TFActionView" bundle:nil title:title body:body];
    [av addActionButton:@"OK" icon:nil actionBlock:^(){
        // cancel button
        [[APP_DELEGATE m_mainController] performSelector:@selector(popOverlay)];
    }];
    
    [[APP_DELEGATE m_mainController] pushOverlay:av];
    
    return 0;
    
}

static int scriptWait(lua_State* L) {
    
    NSString* message = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    
    TFScriptWaitMessage* w = [[TFScriptWaitMessage alloc] initWithNibName:@"TFScriptWaitMessage" bundle:nil];
    [w setMessageStr:message];
    
    [[APP_DELEGATE m_mainController] pushOverlay:w];
    
    return 0;
    
}

static int scriptDismissWait(lua_State* L) {
    
    [[APP_DELEGATE m_mainController] popOverlay];
    return 0;
    
}

static int scriptNotify(lua_State* L) {
    
    /* this is never called directly it always has an interface, +3 on stack */
    NSString* message = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    int val = lua_tointeger(L, 2);
    int icon = lua_tointeger(L, 3);
    BOOL autoShow = YES;
    
    if (!val) {
        autoShow = NO;
    }
    
    [[[[APP_DELEGATE m_mainController] currentTFForm] notificationWindow] addNotification:message autoShow:autoShow icon:icon];
    
    return 0;
}

static int scriptFocusObject(lua_State* L) {
    
    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;
    
    if ([o isKindOfClass:[TFBaseObjectController class]]) {
        if ([o respondsToSelector:@selector(setCurrentFocusedObject)]) {
            [o performSelector:@selector(setCurrentFocusedObject)];
        }
    }
    
    return 0;
}

static int scriptChangePage(lua_State* L) {
    
    /* find the object and call the focus method, first look at the data type being passed into the call */
    if (lua_isnumber(L, 1)) {
        
        double page = lua_tonumber(L, 1);
        page -=1;
        [[[APP_DELEGATE m_mainController] currentTFForm] setPage:(int)page];
        
    } else if (lua_isstring(L, 1)) {
        
        /* this could be the alias or fqn go looking */
        NSString* ref = [NSString stringWithUTF8String:lua_tostring(L, 1)];
        
        int i=0;
        for (TFPage* p in APP_DELEGATE.m_mainController.currentTFForm.formPages) {
            
            if ([[p getStringProperty:TF_PROPERTY_TITLE] isEqualToString:ref] || [[p getStringProperty:TF_PROPERTY_ALIAS] isEqualToString:ref] || [[p getStringProperty:TF_PROPERTY_FIELDNAME] isEqualToString:ref] ) {
                
               [[[APP_DELEGATE m_mainController] currentTFForm] setPage:i];
                
            }
            
            i++;
            
        }
        
    }
    
    return 0;
}

static int scriptSetField(lua_State* L) {
    
    /* find the object and call the focus method */
    NSString* key = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    NSObject* value;
    
    if (lua_isstring(L, 2)) {
        value = [NSString stringWithUTF8String:lua_tostring(L, 2)];
    }
    
    if (lua_isnumber(L, 2)) {
        value = [NSNumber numberWithDouble:lua_tonumber(L, 2)];
    }
    
    if (lua_isnil(L, 2)) {
        value = [NSNull null];
    }
    
    [[[APP_DELEGATE m_mainController] currentTFForm] updateFieldWithObject:value forField:key cascadeToLua:NO];
    
    return 0;
}

static int scriptGetField(lua_State* L) {
    
    /* find the object and call the focus method */
    NSString* key = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    NSObject* value = [[[APP_DELEGATE m_mainController] currentTFForm] getValueInEntityForField:key];
    
    if (value == nil) {
        lua_pushnil(L);
        return 1;
    }
    
    if ([value isKindOfClass:[NSNull class]]) {
        lua_pushnil(L);
        return 1;
    }
    
    if ([value isKindOfClass:[NSNumber class]]) {
        lua_pushnumber(L, [((NSNumber*)value) doubleValue]);
        return 1;
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        lua_pushstring(L, [((NSString*)value) UTF8String]);
        return 1;
    }
    
    return 0;
    
}

static int scriptCloseForm(lua_State* L) {

    /* we need to delay this transaction as the lua vm is still mid way through a transaction and a ne form destroys it */
    [[APP_DELEGATE m_mainController] performSelector:@selector(defaultScreen) withObject:nil afterDelay:0.2];
    return 0;
    
}

static int scriptOpenForm(lua_State* L) {
    
    NSString* formName = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    /* we need to delay this transaction as the lua vm is still mid way through a transaction and a ne form destroys it */
    [[APP_DELEGATE m_mainController] performSelector:@selector(openFormNamed:) withObject:formName afterDelay:0.2];
    return 0;
    
}

static int scriptSaveForm(lua_State* L) {

    [[[APP_DELEGATE m_mainController] currentTFForm] updateDataEntity];
    return 0;
}

static int scriptDeleteForm(lua_State* L) {
    
    GenericEntity* ge = [[[APP_DELEGATE m_mainController] currentTFForm] formDataEntity];
    /* we need to delay this transaction as the lua vm is still mid way through a transaction and a ne form destroys it */
    [[APP_DELEGATE m_mainController] performSelector:@selector(defaultScreen) withObject:nil afterDelay:0.2];
    [ge remove];
    
    return 0;
}

static int scriptGetUserData(lua_State* L) {
    
    /* find the object and call the focus method */
    NSString* key = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    NSObject* value = [[APP_DELEGATE m_mainController] getPersistentUserDataForKey:key];
    
    if (value == nil) {
        lua_pushnil(L);
        return 1;
    }
    
    if ([value isKindOfClass:[NSNull class]]) {
        lua_pushnil(L);
        return 1;
    }
    
    if ([value isKindOfClass:[NSNumber class]]) {
        lua_pushnumber(L, [((NSNumber*)value) doubleValue]);
        return 1;
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        lua_pushstring(L, [((NSString*)value) UTF8String]);
        return 1;
    }
    
    return 0;
    
}

static int scriptGetCurrentUserEmail(lua_State* L) {
    
    /* pull this out of the users table */
    
    EntitySet* es = [[EntitySet alloc] initWithTablename:@"users"];
    es.restrictions = @"currentuser=1";
    [es execute];
    if (es.rowCount > 0) {
        GenericEntity* ge = [es getEntityForIndex:0];
        NSString* username = (NSString*)[ge getField:@"username"];
        lua_pushstring(L, [username UTF8String]);
        return 1;
    }
    
    return 0;
    
}

static int scriptSetUserData(lua_State* L) {
    
    /* find the object and call the focus method */
    NSString* key = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    NSObject* value;
    
    if (lua_isstring(L, 2)) {
        value = [NSString stringWithUTF8String:lua_tostring(L, 2)];
    }
    
    if (lua_isnumber(L, 2)) {
        value = [NSNumber numberWithDouble:lua_tonumber(L, 2)];
    }
    
    if (lua_isnil(L, 2)) {
        value = [NSNull null];
    }
    
    [[APP_DELEGATE m_mainController] setPersistentUserData:value forKey:key];
    
    return 0;
}

static int scriptShowMenu(lua_State* L) {

    [[APP_DELEGATE m_mainController] showMenu];
    return 0;
}

static int scriptClearNotificationsList(lua_State* L) {
    
    [[[APP_DELEGATE m_mainController] currentTFForm] clearNotifications];
    return 0;
    
}

static int scriptShowNotificationsList(lua_State* L) {
    
    [[[APP_DELEGATE m_mainController] currentTFForm] showNotifications];
    return 0;
    
}

static int scriptHideNotificationsList(lua_State* L) {
    
    [[[APP_DELEGATE m_mainController] currentTFForm] hideNotifications];
    return 0;
    
}


static int scriptAddItemToSelect(lua_State* L) {
    
    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;
    NSString* value = [NSString stringWithUTF8String:lua_tostring(L, 2)];
    NSString* description = [NSString stringWithUTF8String:lua_tostring(L, 3)];
    
    if ([o isKindOfClass:[TFSelect class]]) {
        [((TFSelect*)o) addValue:value description:description];
    }
    
    return 0;
    
}

static int scriptGetDescriptionFromSelect(lua_State* L) {
    
    
    
}

static int scriptClearSelect(lua_State* L) {
    
    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;

    if ([o isKindOfClass:[TFSelect class]]) {
        [((TFSelect*)o) clear];
    }
    
    return 0;
    
}

static int scriptRemoveItemFromSelect(lua_State* L) {
   
    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;
    NSString* value = [NSString stringWithUTF8String:lua_tostring(L, 2)];
    
    if ([o isKindOfClass:[TFSelect class]]) {
        [((TFSelect*)o) delValue:value];
    }
    
    return 0;
    
}

static int scriptSetImageFromUrl(lua_State* L) {
    
    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;
    NSString* value = [NSString stringWithUTF8String:lua_tostring(L, 2)];
    NSURL* url = [NSURL URLWithString:value];
    
    if ([o isKindOfClass:[TFImage class]]) {
        [((TFImage*)o) setWithUrl:url];
    }
    
    return 0;
    
}

static int scriptGetStringFromURL(lua_State* L) {
    
    /* find the object and call the focus method */
    NSString* value = [NSString stringWithUTF8String:lua_tostring(L, 1)];
    NSURL* url = [NSURL URLWithString:value];
    NSError* error;
    NSString* str= [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error];
    
    if (!error && str) {
        lua_pushstring(L, [str UTF8String]);
    } else {
        lua_pushnil(L);
    }
    
    return 1;
    
}

/* multi select object */

static int scriptGetOptionsCountForMultiSelect(lua_State* L) {

    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;
    
    if ([o isKindOfClass:[TFMultiSelect class]]) {
        lua_pushnumber(L, (double)[((TFMultiSelect*)o) optionCount]);
        return 1;
    }
    
    return 0;

}

static int scriptGetOptionValueForIndexForMultiSelect(lua_State* L) {
    
    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    double idx = lua_tonumber(L,2);
    
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;
    
    if ([o isKindOfClass:[TFMultiSelect class]]) {
        lua_pushstring(L, [[((TFMultiSelect*)o) optionValue:(int)idx] UTF8String]);
        return 1;
    }
    
    return 0;
    
}

static int scriptGetOptionTitleForIndexForMultiSelect(lua_State* L) {
    
    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    double idx = lua_tonumber(L,2);
    
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;
    
    if ([o isKindOfClass:[TFMultiSelect class]]) {
        lua_pushstring(L, [[((TFMultiSelect*)o) optionTitle:(int)idx] UTF8String]);
        return 1;
    }
    
    return 0;
    
}

static int scriptGetOptionSelectedForIndexForMultiSelect(lua_State* L) {
    
    /* find the object and call the focus method */
    double memAddr = lua_tonumber(L, 1);
    double idx = lua_tonumber(L,2);
    
    NSObject* o = (__bridge NSObject*)(void*)(unsigned int)memAddr;
    
    if ([o isKindOfClass:[TFMultiSelect class]]) {
        lua_pushboolean(L, (int)[((TFMultiSelect*)o) optionSelected:(int)idx]);
        return 1;
    }
    
    return 0;
    
}



/* debugging support, as it has become just too hard to work out  */



static int scriptStartDebug(lua_State* L) {
    
    if ([[[APP_DELEGATE m_mainController] currentTFForm] formIsInTest]) {
        if (![APP_DELEGATE isDebugging]) {
            [APP_DELEGATE setIsDebugging:YES];
            NSString* code = [NSString stringWithUTF8String:lua_tostring(L, 1)];
            [APP_DELEGATE setDebugStartedFromThisEvent:code];
        }
        
        [APP_DELEGATE setDebugStep:0]; /* break NOW! */
        
        if(!debugTimer) {
            debugTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:[CScriptInterface class] selector:@selector(debugTimerTick) userInfo:nil repeats:YES];
            debugState = L;
        }
    }
    return 0;
    
}

static int scriptStopDebug(lua_State* L) {
    
    [APP_DELEGATE setIsDebugging:NO];
    return 0;
    
}

static int scriptBreakForAction(lua_State* L) {
    
    /* in the future we might want more than the line number to get passed in e.g. variables in scope! */
    if ([APP_DELEGATE isDebugging]) {
        
        /* keep the current debug block state up to date */
        debugState = L;
    
        /* we stop here because we are out of steps, param1 = line no,param 2 = the event, param3 = the code for this event */
        
        int lineNo = (int)lua_tonumber(L, 1);
        
        [APP_DELEGATE setDebugLastLine:lineNo];
        
        NSString* eventName = [NSString stringWithUTF8String:lua_tostring(L, 2)];
        NSString* code = [NSString stringWithUTF8String:lua_tostring(L, 3)];
    
        int varCount = lua_gettop(L);
        varCount -= 3;
        varCount = (int)varCount / 2;
    
        NSMutableArray* params = [NSMutableArray new];
        if (varCount) {
            
            int pIndex = 4;
            
            while (pIndex < (varCount*2)+3) {
                NSString* name = [NSString stringWithUTF8String:lua_tostring(L, pIndex)];
                NSString* value = @"nil";
                if (lua_isnumber(L, pIndex+1)) {
                    value = [NSString stringWithFormat:@"%@ (number)",[[NSNumber numberWithDouble:lua_tonumber(L, pIndex+1)] stringValue]];
                }
                else if (lua_isstring(L, pIndex+1)) {
                    value = [NSString stringWithFormat:@"\"%@\" (string)(%i chars)",[NSString stringWithUTF8String:lua_tostring(L, pIndex+1)],[[NSString stringWithUTF8String:lua_tostring(L, pIndex+1)] length]];
                }  else if (lua_isboolean(L, pIndex+1)) {
                    if (lua_toboolean(L, pIndex+1)) {
                        value = @"true (boolean)";
                    } else {
                        value = @"false (boolean)";
                    }
                }
                
                NSMutableDictionary* d = [NSMutableDictionary new];
                [d setObject:value forKey:@"value"];
                [d setObject:name forKey:@"name"];
                
                [params addObject:d];
                pIndex+=2;
            }
        
        }
        
        if (![APP_DELEGATE scriptDebugDialog]) {
            // no dialog, create a new one
            TFScriptDebugger* d = [[TFScriptDebugger alloc] initWithNibName:@"TFScriptDebugger" bundle:nil];
            [APP_DELEGATE setScriptDebugDialog:d];
        }
        
        [[APP_DELEGATE scriptDebugDialog] setCode:code forEvent:eventName currentLine:lineNo withVariables:params];
        
        if (![[[APP_DELEGATE m_mainController] overlayViewController] isEqual:[APP_DELEGATE scriptDebugDialog]]) {
            [[APP_DELEGATE m_mainController] pushOverlay:[APP_DELEGATE scriptDebugDialog]];
        }
        
        NSLog(@"debugging line number %i, for event %@", lineNo, eventName);
        
    }
    
    return 0;
    
}

/* date and time functions */

static int scriptToday(lua_State* L) {
    
    lua_pushstring(L, [[TFLocalisedDate localisedShortDateStringWithDate:[NSDate date]] UTF8String]);
    return 1;
    
}

static int scriptNow(lua_State* L) {
    
    lua_pushstring(L, [[TFLocalisedDate localisedShortTimeStringWithDate:[NSDate date]] UTF8String]);
    return 1;
    
}

/* vm error state handling */

static int scriptRaiseAbort(lua_State* L) {
    
    lua_pushboolean(L, 1);
    lua_setglobal(L, "__ABORT__");
    return 0;
    
}

#pragma mark registration of functions

- (void)registerFunctionsFromStatic:(BOOL)staticInstance {
    
    luaL_openlibs(scriptEngine);
    [self execute:[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tabletforms_language.lua"]] encoding:NSUTF8StringEncoding] eventName:@"" silent:NO];
    
    lua_register(scriptEngine, "__tablechange", scriptHandlePropertyChange);
    lua_register(scriptEngine, "__tableget", scriptHandlePropertyGet);
    lua_register(scriptEngine, "__submit", scriptSubmitData);
    lua_register(scriptEngine, "__alert", scriptAlertMessage);
    lua_register(scriptEngine, "__notify", scriptNotify);
    lua_register(scriptEngine, "__focusObject", scriptFocusObject);
    lua_register(scriptEngine, "__changePage", scriptChangePage);
    lua_register(scriptEngine, "__setField", scriptSetField);
    lua_register(scriptEngine, "__getField", scriptGetField);
    lua_register(scriptEngine, "__closeForm", scriptCloseForm);
    lua_register(scriptEngine, "__openForm", scriptOpenForm);
    lua_register(scriptEngine, "__saveForm", scriptSaveForm);
    lua_register(scriptEngine, "__deleteForm", scriptDeleteForm);
    lua_register(scriptEngine, "__setUserData", scriptSetUserData);
    lua_register(scriptEngine, "__getUserData", scriptGetUserData);
    lua_register(scriptEngine, "__getCurrentUserEmail", scriptGetCurrentUserEmail);
    lua_register(scriptEngine, "__clearNotificationsList", scriptClearNotificationsList);
    lua_register(scriptEngine, "__showNotificationsList", scriptShowNotificationsList);
    lua_register(scriptEngine, "__hideNotificationsList", scriptHideNotificationsList);
    lua_register(scriptEngine, "__showSideMenu", scriptShowMenu);
    lua_register(scriptEngine, "__wait", scriptWait);
    lua_register(scriptEngine, "__dismissWait", scriptDismissWait);    
    lua_register(scriptEngine, "__setImageFromURL", scriptSetImageFromUrl);
    lua_register(scriptEngine, "__addItemToSelectObject", scriptAddItemToSelect);
    lua_register(scriptEngine, "__getDescriptionForSelectObject", scriptGetDescriptionFromSelect);
    
    
    lua_register(scriptEngine, "__msCount", scriptGetOptionsCountForMultiSelect);
    lua_register(scriptEngine, "__msTitleForIndex", scriptGetOptionTitleForIndexForMultiSelect);
    lua_register(scriptEngine, "__msValueForIndex", scriptGetOptionValueForIndexForMultiSelect);
    lua_register(scriptEngine, "__msSelectedForIndex", scriptGetOptionSelectedForIndexForMultiSelect);
    
    lua_register(scriptEngine, "__clearSelectObject", scriptClearSelect);
    lua_register(scriptEngine, "__removeItemFromSelectObject", scriptRemoveItemFromSelect);
    lua_register(scriptEngine, "__getStringFromURL", scriptGetStringFromURL);
    lua_register(scriptEngine, "__breakWait", scriptBreakForAction);
    lua_register(scriptEngine, "__today", scriptToday);
    lua_register(scriptEngine, "__now", scriptNow);
    lua_register(scriptEngine, "debug", scriptStartDebug);
    lua_register(scriptEngine, "debugend", scriptStopDebug);
    lua_register(scriptEngine, "abort", scriptRaiseAbort);
    
//    lua_register(scriptEngine, "__createTimer", );
//    lua_register(scriptEngine, "__deleteTimer", );
//    lua_register(scriptEngine, "__openFormWithReference", );

}

#pragma mark engine utilities

NSMutableArray* variablesInScope(NSString* code, int lineNo) {
    
    NSMutableDictionary* scopeVars = [NSMutableDictionary new];
    
    for (int i=1; i<99; i++) {
        NSNumber* n = [NSNumber numberWithInt:i];
        [scopeVars setObject:[NSMutableArray new] forKey:[n stringValue]];
    }
    
    int currLine = 1;
    NSNumber* currentScope = [NSNumber numberWithInt:1];
    NSArray* lines = [code componentsSeparatedByString:@"\n"];
    for (NSString* line in lines) {
        
        /* remove left hand whitespace */
        NSString* l = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"    "]];
        
        if ([l rangeOfString:@"local "].location != NSNotFound) {
            /* there is a variable declaration */
            NSString* varName = [l substringFromIndex:[l rangeOfString:@"local "].location + 6];
            varName = [varName substringToIndex:[varName rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" ()=+{}&^%$£@!;:|/?><,`~"]].location];
            NSMutableArray* a = [scopeVars objectForKey:[currentScope stringValue]];
            if (![varName isEqualToString:@"this"]) {
                [a addObject:varName];
                [scopeVars setObject:a forKey:[currentScope stringValue]];
            }
        }
        
        if ([l rangeOfString:@"if "].location != NSNotFound || [l rangeOfString:@"if("].location != NSNotFound || [l rangeOfString:@"for "].location != NSNotFound|| [l rangeOfString:@"for("].location != NSNotFound || [l rangeOfString:@"while "].location != NSNotFound || [l rangeOfString:@"while("].location != NSNotFound) {
            currentScope = [NSNumber numberWithInt:[currentScope intValue]+1];
        }
        
        if ([l rangeOfString:@"end "].location != NSNotFound || [l rangeOfString:@"end;"].location != NSNotFound) {
            
            /* remove the entries at the current scope */
            [scopeVars setObject:[NSMutableArray new] forKey:[currentScope stringValue]];
            
            currentScope = [NSNumber numberWithInt:[currentScope intValue]-1];
            if ([currentScope intValue] < 1) {
                [NSNumber numberWithInt:1];
            }
        }
        
        currLine+=1;
        if (currLine >= lineNo) {
            break;
        }
    }
    
    /* now get all of the variables into one array */
    NSMutableArray* arr = [NSMutableArray new];
    
    for (NSArray* a in scopeVars.allValues) {
        if ([a count]>0) {
            for (id object in a) {
                [arr addObject:object];
            }
        }
    }
    
    return arr;
    
}


NSMutableArray* referencedGlobalsInCode(NSString* code) {
    
    
    //JCG
    NSLog(@"referencedGlobalsInCode");
    
    
    NSMutableArray* results = [NSMutableArray new];
    
    for (id obj in [[[APP_DELEGATE m_mainController] currentTFForm] formObjects]) {
        
        if ([obj isKindOfClass:[TFBaseObjectController class]]) {
            
            TFBaseObjectController* formObj = (TFBaseObjectController*)obj;
            NSString* objectName = [formObj getStringProperty:TF_PROPERTY_FIELDNAME];
            
            NSString* valKey = [NSString stringWithFormat:@"%@.value", objectName];
            NSString* titleKey = [NSString stringWithFormat:@"%@.title", objectName];
            NSString* hiddenKey = [NSString stringWithFormat:@"%@.hidden", objectName];
            NSString* enabledKey = [NSString stringWithFormat:@"%@.enabled", objectName];
            NSString* validKey = [NSString stringWithFormat:@"%@.valid", objectName];
            NSString* messageKey = [NSString stringWithFormat:@"%@.message", objectName];
            
            if ([code rangeOfString:valKey].location != NSNotFound) {
                [results addObject:valKey];
            }
            
            if ([code rangeOfString:titleKey].location != NSNotFound) {
                [results addObject:titleKey];
            }
            
            if ([code rangeOfString:hiddenKey].location != NSNotFound) {
                [results addObject:hiddenKey];
            }
            
            if ([code rangeOfString:enabledKey].location != NSNotFound) {
                [results addObject:enabledKey];
            }
            
            if ([code rangeOfString:validKey].location != NSNotFound) {
                [results addObject:validKey];
            }
            
            if ([code rangeOfString:messageKey].location != NSNotFound) {
                [results addObject:messageKey];
            }
            
        }
        
    }
    
    /* alias objects */
    
    for (id obj in [[[APP_DELEGATE m_mainController] currentTFForm] formObjects]) {
        
        if ([obj isKindOfClass:[TFBaseObjectController class]]) {
            
            TFBaseObjectController* formObj = (TFBaseObjectController*)obj;
            NSString* objectName = [formObj getObjectAlias];
            
            //JCG adding test for blank alias too
            
            if (objectName && ![objectName isEqualToString:@""] ) {
                
                NSString* valKey = [NSString stringWithFormat:@"%@.value", objectName];
                NSString* titleKey = [NSString stringWithFormat:@"%@.title", objectName];
                NSString* hiddenKey = [NSString stringWithFormat:@"%@.hidden", objectName];
                NSString* enabledKey = [NSString stringWithFormat:@"%@.enabled", objectName];
                NSString* validKey = [NSString stringWithFormat:@"%@.valid", objectName];
                NSString* messageKey = [NSString stringWithFormat:@"%@.message", objectName];
                
                if ([code rangeOfString:valKey].location != NSNotFound) {
                    [results addObject:valKey];
                }
                
                if ([code rangeOfString:titleKey].location != NSNotFound) {
                    [results addObject:titleKey];
                }
                
                if ([code rangeOfString:hiddenKey].location != NSNotFound) {
                    [results addObject:hiddenKey];
                }
                
                if ([code rangeOfString:enabledKey].location != NSNotFound) {
                    [results addObject:enabledKey];
                }
                
                if ([code rangeOfString:validKey].location != NSNotFound) {
                    [results addObject:validKey];
                }
                
                if ([code rangeOfString:messageKey].location != NSNotFound) {
                    [results addObject:messageKey];
                }
            }
            
        }
        
    }
    
    /* this objects */
    
    if ([code rangeOfString:@"this."].location != NSNotFound) {
        
        NSString* objectName = @"this";
        
        NSString* valKey = [NSString stringWithFormat:@"%@.value", objectName];
        NSString* titleKey = [NSString stringWithFormat:@"%@.title", objectName];
        NSString* hiddenKey = [NSString stringWithFormat:@"%@.hidden", objectName];
        NSString* enabledKey = [NSString stringWithFormat:@"%@.enabled", objectName];
        NSString* validKey = [NSString stringWithFormat:@"%@.valid", objectName];
        NSString* messageKey = [NSString stringWithFormat:@"%@.message", objectName];
        
        
        if ([code rangeOfString:valKey].location != NSNotFound) {
            [results addObject:valKey];
        }
        
        if ([code rangeOfString:titleKey].location != NSNotFound) {
            [results addObject:titleKey];
        }
        
        if ([code rangeOfString:hiddenKey].location != NSNotFound) {
            [results addObject:hiddenKey];
        }
        
        if ([code rangeOfString:enabledKey].location != NSNotFound) {
            [results addObject:enabledKey];
        }
        
        if ([code rangeOfString:validKey].location != NSNotFound) {
            [results addObject:validKey];
        }
        
        if ([code rangeOfString:messageKey].location != NSNotFound) {
            [results addObject:messageKey];
        }
    }
    
    
    //JCG
    NSLog(@"referencedGlobalsInCode: %i", [results count]);
    
    return results;
    
    
    
//    NSMutableSet *formObjectNames = [[NSMutableSet alloc] init];
//    
//    //add the 'this' catch all
//    [formObjectNames addObject:@"this"];
//    
//    for (id obj in [[[APP_DELEGATE m_mainController] currentTFForm] formObjects]) {
//        
//        if ([obj isKindOfClass:[TFBaseObjectController class]]) {
//            
//            TFBaseObjectController* formObj = (TFBaseObjectController*)obj;
//            NSString* alias = [formObj getObjectAlias];
//            
//            if (alias && ![alias isEqualToString:@""])
//                [formObjectNames addObject:alias];
//
//            
//            NSString* fieldName = [formObj getStringProperty:TF_PROPERTY_FIELDNAME];
//            
//            if (fieldName && ![fieldName isEqualToString:@""])
//                [formObjectNames addObject:fieldName];
//            
//            
//        }
//    }
//    
//    
//    NSString *allNames = [[formObjectNames allObjects] componentsJoinedByString:@"|"];
//    
//    NSString *pattern = [NSString stringWithFormat:@"((%@)(\\.value|\\.title|\\.hidden|\\.enabled|\\.valid|\\.message))", allNames];
//    
//    
//    NSError *error = nil;
//    
//    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:nil error:&error];
//    
//    NSArray *matches = [regex matchesInString:code options:nil range:NSMakeRange(0, code.length)];
//    
//    NSLog(@"Matches=%i", matches.count);
//    
//    NSMutableSet *set = [[NSMutableSet alloc] init];
//    
//    for (NSTextCheckingResult * match in matches) {
//        NSRange range = [match rangeAtIndex:1];
//        NSString *capture = [code substringWithRange:range];
//        [set addObject:capture];
//    }
//    
//    NSLog(@"set=%i", set.count);
//    
//    
//    return [[NSMutableArray alloc] initWithArray: [set allObjects]];
//    
    
}

- (void)executeRaw:(NSString*)script {
    //JCG
    NSLog(@"executeRaw");
    luaL_dostring(scriptEngine, script.UTF8String);
}

- (int)execute:(NSString*)script eventName:(NSString*)eventName silent:(BOOL)silent {
    
    
    //JCG
    NSLog(@"execute script - \t%@", eventName);
    
    silent = NO;
    
    NSString* originalScript = [NSString stringWithString:script];
    
    /* prepare script if the current form is in test */
    if ([[[APP_DELEGATE m_mainController] currentTFForm] formIsInTest] && ![eventName isEqualToString:@""]) {
        if (![APP_DELEGATE isDebugging]) {
            
            NSMutableArray* referencedGlobals = referencedGlobalsInCode(script);
            NSString* globalParams = @"";
            for (NSString* var in referencedGlobals) {
                globalParams = [globalParams stringByAppendingFormat:@",\"%@\", %@", var, var];
            }
        
            NSString* safeScript = [NSString stringWithString:script];
            safeScript = [safeScript stringByReplacingOccurrencesOfString:@"[[" withString:@"^^^"];
            safeScript = [safeScript stringByReplacingOccurrencesOfString:@"]]" withString:@"^*^"];
            
            /* create an array from the original script now */
            NSArray* a = [originalScript componentsSeparatedByString:@"\n"];

            script = @"local __coroutine = coroutine.create( function() \n";
            
            int i=1;
            BOOL debugFound = NO;
            for (NSString* s in a) {
                if(debugFound) {
                    
                    NSMutableArray* referencedLocals = variablesInScope(originalScript, i);
                    NSString* localVars = @"";
                    for (NSString* var in referencedLocals) {
                        localVars = [localVars stringByAppendingFormat:@",\"%@\", %@", var, var];
                    }
                    
                    script = [script stringByAppendingString:[NSString stringWithFormat:@"__breakWait(%i,[[_eventname_]],[[_originalscript_]]%@%@); coroutine.yield();",i, localVars, globalParams]];
                    script = [script stringByAppendingString:@"\n"];
                }
                script = [script stringByAppendingString:s];
                script = [script stringByAppendingString:@"\n"];
                if ([s rangeOfString:@"debug()"].location != NSNotFound) {
                    debugFound = YES;
                }
                i+=1;
            }
            
            script = [script stringByAppendingString:@"\n __coroutine = nil; debugend(); \n end )\n coroutine.resume(__coroutine);\n"];
            script = [script stringByReplacingOccurrencesOfString:@"debug()" withString:@"debug([[_originalscript_]])"];
            script = [script stringByReplacingOccurrencesOfString:@"_originalscript_" withString:safeScript];
            script = [script stringByReplacingOccurrencesOfString:@"_eventname_" withString:eventName];
        }        
        
    } else {
        /* strip out the debug commands if there are any found */
        /*
        NSError *error = nil;
        script = [[[NSRegularExpression alloc] initWithPattern:@"debug\\s*\(\\);*" options:nil error:&error]
                  stringByReplacingMatchesInString:script options:nil range:NSMakeRange(0, [script length]) withTemplate:@""];
        */
        script = [script stringByReplacingOccurrencesOfString:@"debug ();" withString:@""];
        script = [script stringByReplacingOccurrencesOfString:@"debug ()" withString:@""];
        script = [script stringByReplacingOccurrencesOfString:@"debug();" withString:@""];
        script = [script stringByReplacingOccurrencesOfString:@"debug()" withString:@""];
        
    }
    
    int result = (int)luaL_dostring(scriptEngine, [script UTF8String]);
    if (result && (!silent || [APP_DELEGATE isDebugging])) {
        
        lua_pop(scriptEngine, 1); // pop the error to avoid destabalising the stack
        
        // ]:$:
        
        /* now we need to run the original version of the script without the debug, as the debug may have caused the error and if not we need the real line number outside of the co-routine version */
        result = (int)luaL_dostring(scriptEngine, [originalScript UTF8String]);
        if (result && (!silent || [APP_DELEGATE isDebugging])) {
            
            /* there was an error, error is pushed onto the stack and the position is re-pushed in front */
            const char* errMessage = lua_tostring(scriptEngine,-1);
            NSString* errorMsg = [NSString stringWithUTF8String:errMessage];
            
            NSLog(@"\n************************************\n$Runtime Scripting Error\n************************************\n\nError : %@\n************************************\n\nScript : \n%@", errorMsg, script);
            
            lua_pop(scriptEngine, 1); // pop the error to avoid destabalising the stack
        
            NSString* errLine = [errorMsg substringFromIndex:[errorMsg rangeOfString:@"]:"].location + 2];
            errLine = [errLine substringToIndex:[errLine rangeOfString:@":"].location];
            
            errorMsg = [errorMsg substringFromIndex:[errorMsg rangeOfString:@"]:"].location + 2];
            errorMsg = [errorMsg substringFromIndex:[errorMsg rangeOfString:@":"].location + 1];
            
            TFScriptErrorViewController* d = [[TFScriptErrorViewController alloc] initWithNibName:@"TFScriptErrorViewController" bundle:nil];
            [d setCode:originalScript forEvent:eventName currentLine:[errLine intValue] withErrorDescription:errorMsg];
       
            [APP_DELEGATE setIsDebugging:NO];
            [APP_DELEGATE setDebugStep:0];
            if (debugTimer) {
                [debugTimer invalidate];
                debugTimer = nil;
            }
            
            /* if debugging dialog present the poop-can the dialog ready to push a new one */
            UIViewController* vc = (UIViewController*)[[APP_DELEGATE m_mainController] overlayViewController];
            if ([vc isKindOfClass:[TFScriptDebugger class]]) {
                [[APP_DELEGATE m_mainController] popOverlay];
            }
            
            [[APP_DELEGATE m_mainController] pushOverlay:d];
            
            return SCRIPT_EXECUTE_ERROR;
        }
        
    }
    else {
        
        
    }
    
    /* check user raised errors such as abort() */
    
    BOOL abortFlag = NO;
    lua_getglobal(scriptEngine,"__ABORT__");
    if (!lua_isnil(scriptEngine, 1)) {
        abortFlag = lua_toboolean(scriptEngine, 1);
    }
    lua_pop(scriptEngine,1);
    
    if (abortFlag) {
        return SCRIPT_RAISE_ABORT;
    }
    
    return SCRIPT_EXECUTE_OK;
    
}

+ (int)staticExecute:(NSString *)code forEvent:(NSString*)eventName {
    
    CScriptInterface* L = [[CScriptInterface alloc] init:YES];
    return [L execute:code eventName:eventName silent:NO];
    
}

@end

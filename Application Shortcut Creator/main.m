//
//  main.m
//  Application Shortcut Creator
//
//  Created by mii on 2013/02/04.
//  Copyright (c) 2013年 mii. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, char *argv[])
{
    [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
    return NSApplicationMain(argc, (const char **)argv);
}

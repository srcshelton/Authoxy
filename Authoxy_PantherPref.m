//
//  Authoxy_PantherPref.m
//  Authoxy-Panther
//
//  Created by Heath Raftery on Sun Dec 28 2003.
//  Copyright (c) 2003, 2004 HRSoftWorks. All rights reserved.
//
//  This file is part of Authoxy.
//
//  Authoxy is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  Authoxy is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Authoxy; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#import "Authoxy_PantherPref.h"

#include <syslog.h>

@implementation Authoxy_PantherPref

/**************************************************************/
/* initWithBundle                                             */
/* initialisation procedures. Set up the preference defaults  */
/**************************************************************/
- (id)initWithBundle:(NSBundle *)bundle
{
  if ( ( self = [super initWithBundle:bundle] ) != nil )
  {
    CFPropertyListRef value;

    appID = CFSTR("net.hrsoftworks.AuthoxyPref");

    lastSysModDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)0];
    lastPIDModDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)0];
    lastPortModDate =[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:(NSTimeInterval)0]; 

    value = CFPreferencesCopyAppValue(CFSTR(AP_Authorization), appID);
    if (!(value && CFGetTypeID(value) == CFStringGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_Authorization), @"Undefined", appID);

    value = CFPreferencesCopyAppValue(CFSTR(AP_Address), appID);
    if (!(value && CFGetTypeID(value) == CFStringGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_Address), @"proxy.myhost.edu.au", appID);

    value = CFPreferencesCopyAppValue(CFSTR(AP_RemotePort), appID);
    if (!(value && CFGetTypeID(value) == CFStringGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_RemotePort), @"8080", appID);

    value = CFPreferencesCopyAppValue(CFSTR(AP_LocalPort), appID);
    if (!(value && CFGetTypeID(value) == CFStringGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_LocalPort), @"8080", appID);

    value = CFPreferencesCopyAppValue(CFSTR(AP_Logging), appID);
    if (!(value && CFGetTypeID(value) == CFBooleanGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_Logging), kCFBooleanFalse, appID);

    value = CFPreferencesCopyAppValue(CFSTR(AP_PromptCredentials), appID);
    if (!(value && CFGetTypeID(value) == CFBooleanGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_PromptCredentials), kCFBooleanFalse, appID);
    
//    value = CFPreferencesCopyAppValue(CFSTR(AP_AutoStart), appID);
//    if (!(value && CFGetTypeID(value) == CFBooleanGetTypeID()))
//    CFPreferencesSetAppValue(CFSTR(AP_AutoStart), kCFBooleanFalse, appID);

    value = CFPreferencesCopyAppValue(CFSTR(AP_DaemonPID), appID);
    if (!(value && CFGetTypeID(value) == CFNumberGetTypeID()))
    {
      int minusOne = -1;
      CFPreferencesSetAppValue(CFSTR(AP_DaemonPID),
                               CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &minusOne),
                               appID);
    }

    value = CFPreferencesCopyAppValue(CFSTR(AP_AutoConfig), appID);
    if (!(value && CFGetTypeID(value) == CFBooleanGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_AutoConfig), kCFBooleanFalse, appID);

    value = CFPreferencesCopyAppValue(CFSTR(AP_PACAddress), appID);
    if (!(value && CFGetTypeID(value) == CFStringGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_PACAddress), @"http://www.myhost.edu.au/proxy.pac", appID);

    //NTLM settings
    value = CFPreferencesCopyAppValue(CFSTR(AP_NTLM), appID);
    if (!(value && CFGetTypeID(value) == CFBooleanGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_NTLM), kCFBooleanFalse, appID);
    
    value = CFPreferencesCopyAppValue(CFSTR(AP_NTLM_Domain), appID);
    if (!(value && CFGetTypeID(value) == CFStringGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_NTLM_Domain), @"domain", appID);

    value = CFPreferencesCopyAppValue(CFSTR(AP_NTLM_Host), appID);
    if (!(value && CFGetTypeID(value) == CFStringGetTypeID()))
      CFPreferencesSetAppValue(CFSTR(AP_NTLM_Host), @"host", appID);

    lastLocalPort = [[NSMutableString alloc] initWithCapacity:32];
    [lastLocalPort setString:@"unknown"];
    
    running = FALSE; //since the button is "Start Authoxy" by default
  }
  return self;
}

/**************************************************************/
/* dealloc                                                    */
/* free the stuff we've alloc'ed                              */
/*                                                            */
/**************************************************************/
- (void)dealloc
{
  [lastSysModDate release];
  [lastPIDModDate release];
  [lastPortModDate release];
  
  [lastLocalPort release];
  
  [super dealloc];
}

/**************************************************************/
/* mainViewDidLoad                                            */
/* fill the boxes with the appropriate values as the view     */
/* comes up                                                   */
/**************************************************************/
- (void)mainViewDidLoad
{
  char *un=NULL, *pw=NULL;

  if(decodePassKey( (unsigned char*)[(NSString*)CFPreferencesCopyAppValue( CFSTR(AP_Authorization), appID ) cString], &un, &pw))
  {
    //decode was unsuccessful, so fill in default values
    [fUsername setStringValue:@"noone"];
    [fPassword setStringValue:@"nowhere"];
  }
  else
  {
    [fUsername setStringValue:[NSString stringWithCString:un]];
    [fPassword setStringValue:[NSString stringWithCString:pw]];
  }

  free(un);
  free(pw);
  
  [fAddress setStringValue:(NSString*)CFPreferencesCopyAppValue(CFSTR(AP_Address), appID)];
  [fRemotePort setStringValue:(NSString*)CFPreferencesCopyAppValue(CFSTR(AP_RemotePort), appID)];
  [fLocalPort setStringValue:(NSString*)CFPreferencesCopyAppValue(CFSTR(AP_LocalPort), appID)];
  [cLogging setState:CFBooleanGetValue(CFPreferencesCopyAppValue(CFSTR(AP_Logging), appID))];
  [cPromptForCredentials setState:CFBooleanGetValue(CFPreferencesCopyAppValue(CFSTR(AP_PromptCredentials), appID))];
  CFNumberGetValue(CFPreferencesCopyAppValue(CFSTR(AP_DaemonPID), appID),
                   kCFNumberSInt32Type,
                   &daemonPID);
  [fPACAddress setStringValue:(NSString*)CFPreferencesCopyAppValue(CFSTR(AP_PACAddress), appID)];
  if(CFBooleanGetValue(CFPreferencesCopyAppValue(CFSTR(AP_AutoConfig), appID)))
    [rAutoConfig performClick:self];
  else
    [rNoAutoConfig performClick:self];
     
  [self setAutoManualConfig:mAutoManualConfig];

  //NTLM
  [fNTLMDomain setStringValue:(NSString*)CFPreferencesCopyAppValue(CFSTR(AP_NTLM_Domain), appID)];
  [fNTLMHost setStringValue:(NSString*)CFPreferencesCopyAppValue(CFSTR(AP_NTLM_Host), appID)];
  [cNTLMEnabled setState:CFBooleanGetValue(CFPreferencesCopyAppValue(CFSTR(AP_NTLM), appID))];
  [self setNTLMConfig:cNTLMEnabled];
  
  //that's it, just set this updateStatus method going every second
  if (statusTimer != nil)
    [statusTimer invalidate];
  statusTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)1
                                                 target:self
                                               selector:@selector(updateStatus:)
                                               userInfo:nil
                                                repeats:YES];
}

/**************************************************************/
/* willSelect                                                 */
/* Pane has been reselected. Start the status update timer    */
/**************************************************************/
- (void)willSelect;
{
  //the pane has appeared, so start this status update timer again
  if([statusTimer respondsToSelector:@selector(setFireDate:)])
    if([statusTimer isValid])
      [statusTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1]];
}

/**************************************************************/
/* updateStatus                                               */
/* called periodically to set the status string and           */
/* start/stop button                                          */
/**************************************************************/
- (void)updateStatus:(NSTimer*)theTimer
{
  NSMutableString *statusString = [NSMutableString stringWithCapacity:60];

  NSFileManager *myManager = [NSFileManager defaultManager];
  NSDictionary *authoxydPort = [myManager fileAttributesAtPath:AUTHOXYD_PORT_PATH traverseLink:YES];
  if(authoxydPort)
  {
    NSDate *PortModDate = [authoxydPort objectForKey:NSFileModificationDate];
    if([PortModDate compare:lastPortModDate] == NSOrderedDescending)
    {
      [lastLocalPort setString:[NSString stringWithContentsOfFile:AUTHOXYD_PORT_PATH]];
      
      [lastPortModDate release];
      lastPortModDate = [PortModDate retain];
    }
  }
  
  NSDictionary *authoxydPID = [myManager fileAttributesAtPath:AUTHOXYD_PID_PATH traverseLink:YES];
  if(authoxydPID)
  {
    NSDate *PIDModDate = [authoxydPID objectForKey:NSFileModificationDate];
    if([PIDModDate compare:lastPIDModDate] == NSOrderedDescending)
    {
      NSString *PIDStr = [NSString stringWithContentsOfFile:AUTHOXYD_PID_PATH];
      daemonPID = [PIDStr intValue];
      
      [lastPIDModDate release];
      lastPIDModDate = [PIDModDate retain];
    }
  }
  else
    daemonPID = -1;
  
  if(daemonPID != -1)
  {
    int count;
    int err;
    int name[] = { CTL_KERN, KERN_PROC, KERN_PROC_PGRP, daemonPID};
    size_t length=0;
    kinfo_proc *result;
    //Call sysctl with a NULL buffer to find out how big the result would be
    //if we were to call it with a kinfo_proc buffer.
    //The number of process in the group is then the length divided by the sizeof a single kinfo_proc!
    err = sysctl(name, (sizeof(name) / sizeof(*name)), NULL, &length, NULL, 0);
    //Ha! Gay... we have to call sysctl twice, otherwise the length returned is wrong!
    result = malloc(length);
    err = sysctl(name, (sizeof(name) / sizeof(*name)), result, &length, NULL, 0);
    if((err != -1) && (count = length / sizeof(kinfo_proc)))
    {
      if(count > 1)
        [statusString setString:
          [NSString stringWithFormat:@"%d daemons running\non 127.0.0.1 port %@", count, lastLocalPort]];
      else
        [statusString setString:
          [NSString stringWithFormat:@"%d daemon running\non 127.0.0.1 port %@", count, lastLocalPort]];
      [bStartStop setTitle:@"Stop Authoxy"];
      running=TRUE;
    }
    else
    {
      [statusString setString:@"Not running"];
      [bStartStop setTitle:@"Start Authoxy"];
      running=FALSE;
//      daemonPID=-1;
    }
  }
  else
  {
    [statusString setString:@"Fill settings in and\npress \"Start Authoxy\""];
    [bStartStop setTitle:@"Start Authoxy"];
    running=FALSE;
  }

  [fStatus setStringValue:statusString];

  if([[[tTabs selectedTabViewItem] identifier] isEqualToString:@"tvMessages"])
  {
    //check to see if we should update the messages
    NSDictionary *systemLog = [myManager fileAttributesAtPath:SYSTEM_LOG_PATH traverseLink:YES];
    if(systemLog)
    {
      NSDate *sysModDate = [systemLog objectForKey:NSFileModificationDate];
      if([sysModDate compare:lastSysModDate] == NSOrderedDescending)
      {
        NSString *logStr = [NSString stringWithContentsOfFile:SYSTEM_LOG_PATH];
        NSMutableString *authLogStr = [NSMutableString string];
        NSRange myRange = {0,1};
        NSRange mySearchRange;
        int endIndex, length = [logStr length];
        while(myRange.location < length)
        {
          [logStr getLineStart:&myRange.location end:&endIndex contentsEnd:nil forRange:myRange];
          myRange.length=endIndex-myRange.location;
          mySearchRange = [logStr rangeOfString:@"authoxyd: " options:0 range:myRange];
          if(mySearchRange.length != 0)
          {
            myRange.length = 16; //size of time stamp
            [authLogStr appendString:[logStr substringWithRange:myRange]];
            mySearchRange.location += 8;  //skip the search word
            mySearchRange.length = endIndex-mySearchRange.location;
            [authLogStr appendString:[logStr substringWithRange:mySearchRange]];
          }
          myRange.location = endIndex;
          myRange.length = 1;
        }

        [tMessages setString:authLogStr];
        
        myRange.location = [authLogStr length];
        [tMessages scrollRangeToVisible:myRange];
        
        [lastSysModDate release];
        lastSysModDate = [sysModDate retain];
      }
    }
  }
}

/**************************************************************/
/* didUnselect                                                */
/* PreferencePane has been closed, set settings and clean up  */
/**************************************************************/
- (void)didUnselect
{
  [self setSettings];
  
//and stop the status timer
  if([statusTimer respondsToSelector:@selector(setFireDate:)])
    [statusTimer setFireDate:[NSDate distantFuture]];
}

/**************************************************************/
/* startStop                                                  */
/* button has been clicked. Start or stop daemon as appro     */
/**************************************************************/
- (IBAction)startStop:(id)sender
{
  if(!running)
  {
    /* make sure settings are up to date */
    [self setSettings];

    NSString *daemonPath = [[NSBundle bundleWithIdentifier:@"net.hrsoftworks.AuthoxyPref"] pathForAuxiliaryExecutable:@"authoxyd"];
    if(daemonPath != NULL)
    {
      NSTask *daemon = [NSTask launchedTaskWithLaunchPath:daemonPath arguments:[self getDaemonStartArgs]];
      daemonPID = [daemon processIdentifier] + 1; //plus one because it daemon and increments the PID
                                                  //(hope it doesn't loop or skip or something)
                                                  //WTF? As of 040112, it seems to be PID+2??? Today it's not. Watch this fix_prebinding!
//      if([statusTimer respondsToSelector:@selector(setFireDate:)])
//        [statusTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    else
    {
      if([statusTimer respondsToSelector:@selector(setFireDate:)])
        [statusTimer setFireDate:[NSDate distantFuture]];
      [fStatus setStringValue:@"Fatal Error: Daemon not found.\nReinstall Authoxy"];
    }
  }
  else
  {
//    NSString *kill = [NSString stringWithFormat:@"kill %d", daemonPID];
    system("killall -CONT authoxyd"); //wake the silly buggers up
    system("killall authoxyd");       //and then kill them!!
    
    NSFileManager *man = [NSFileManager defaultManager];
    [man removeFileAtPath:AUTHOXYD_PID_PATH handler:nil];
    [man removeFileAtPath:AUTHOXYD_PORT_PATH handler:nil];
  }
}

/**************************************************************/
/* setAutoManualConfig                                        */
/* Either manual proxy setting or automatic config has been   */
/* selected. Make the necessary changes to the GUI            */
/**************************************************************/
- (IBAction)setAutoManualConfig:(id)sender
{
//  if([rAutoConfig state] == NSOnState)
  if([[sender selectedCell] tag] == AUTO_CELL_TAG)
  {
    [fPACAddress setEnabled:YES];
    [fRemotePort setEnabled:NO];
    [fAddress setEnabled:NO];
  }
  else
  {
    [fPACAddress setEnabled:NO];
    [fRemotePort setEnabled:YES];
    [fAddress setEnabled:YES];
  }
}

/**************************************************************/
/* setNTLMConfig                                              */
/* NTLM support has been toggled. Make the necessary changes  */
/* to the GUI                                                 */
/**************************************************************/
- (IBAction)setNTLMConfig:(id)sender
{
  if([sender state] == NSOnState)
  {
    [fNTLMDomain setEnabled:YES];
    [fNTLMHost setEnabled:YES];
  }
  else
  {
    [fNTLMDomain setEnabled:NO];
    [fNTLMHost setEnabled:NO];
  }
}

/**************************************************************/
/* setSettings                                                */
/* Settings should be written to disk everytime a change is   */
/* made                                                       */
/**************************************************************/
- (void)setSettings
{
  char *encoded;

  encoded = encodePassKey( (char*)[[fUsername stringValue] cString], (char*)[[fPassword stringValue] cString]);

  CFPreferencesSetAppValue(CFSTR(AP_Authorization), [NSString stringWithCString:encoded], appID);
  CFPreferencesSetAppValue(CFSTR(AP_Address), [fAddress stringValue], appID);
  CFPreferencesSetAppValue(CFSTR(AP_RemotePort), [fRemotePort stringValue], appID);
  CFPreferencesSetAppValue(CFSTR(AP_LocalPort), [fLocalPort stringValue], appID);
  if([cLogging state] == NSOnState)
    CFPreferencesSetAppValue(CFSTR(AP_Logging), kCFBooleanTrue, appID);
  else
    CFPreferencesSetAppValue(CFSTR(AP_Logging), kCFBooleanFalse, appID);
  if([cPromptForCredentials state] == NSOnState)
    CFPreferencesSetAppValue(CFSTR(AP_PromptCredentials), kCFBooleanTrue, appID);
  else
    CFPreferencesSetAppValue(CFSTR(AP_PromptCredentials), kCFBooleanFalse, appID);
  
  CFPreferencesSetAppValue(CFSTR(AP_DaemonPID),
                           CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &daemonPID),
                           appID);
  CFPreferencesSetAppValue(CFSTR(AP_PACAddress), [fPACAddress stringValue], appID);
  if([rAutoConfig state] == NSOnState)
    CFPreferencesSetAppValue(CFSTR(AP_AutoConfig), kCFBooleanTrue, appID);
  else
    CFPreferencesSetAppValue(CFSTR(AP_AutoConfig), kCFBooleanFalse, appID);

  //NTLM
  CFPreferencesSetAppValue(CFSTR(AP_NTLM_Domain), [fNTLMDomain stringValue], appID);
  CFPreferencesSetAppValue(CFSTR(AP_NTLM_Host), [fNTLMHost stringValue], appID);
  if([cNTLMEnabled state] == NSOnState)
    CFPreferencesSetAppValue(CFSTR(AP_NTLM), kCFBooleanTrue, appID);
  else
    CFPreferencesSetAppValue(CFSTR(AP_NTLM), kCFBooleanFalse, appID);
  
  free(encoded);
}

/**************************************************************/
/* getDaemonStartArgs                                         */
/* return an array of the arguments for the daemon            */
/**************************************************************/
- (NSArray *)getDaemonStartArgs
{
  /* get the commandline arguments for the daemon from the current settings */
  NSArray *args;

  if(CFBooleanGetValue(CFPreferencesCopyAppValue(CFSTR(AP_AutoConfig), appID)))
  {
    args = [NSArray arrayWithObjects:
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_Authorization), appID),
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_PACAddress), appID),	//note using PACaddress in place of address
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_RemotePort), appID),
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_LocalPort), appID),
      [NSString stringWithString:
        (CFBooleanGetValue(CFPreferencesCopyAppValue(CFSTR(AP_Logging), appID)) ? @"true" : @"false")],
      @"true",	//use auto config
      nil];
  }
  else
  {
    args = [NSArray arrayWithObjects:
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_Authorization), appID),
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_Address), appID),
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_RemotePort), appID),
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_LocalPort), appID),
      [NSString stringWithString:
        (CFBooleanGetValue(CFPreferencesCopyAppValue(CFSTR(AP_Logging), appID)) ? @"true" : @"false")],
      @"false",	//no auto config here
      nil];
  }
  
  if(CFBooleanGetValue(CFPreferencesCopyAppValue(CFSTR(AP_NTLM), appID)))
  {
    NSArray *argsNTLM = [args arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_NTLM_Domain), appID), //add Domain and Host settings if using NTLM
      (NSString*)CFPreferencesCopyAppValue(CFSTR(AP_NTLM_Host), appID),
      nil]];
    
    return argsNTLM;
  }
  else
    return args;
}

/****************************************************************/
/* didSelectTabViewItem                                         */
/* looks like the user selected a different tab. Should be act? */
/****************************************************************/
-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
  if([[tabViewItem identifier] isEqualToString:@"tvMessages"])
  {
    //don't do anything for now
  }
}

@end
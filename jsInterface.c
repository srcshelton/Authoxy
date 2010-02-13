/*
 *  jsInterface.c
 *  Authoxy
 *
 *  Created by Heath Raftery on Fri Jan 2 2004.
 *  Copyright (c) 2003, 2004 HRSoftWorks. All rights reserved.
 *
 
 This file is part of Authoxy.
 
 Authoxy is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 Authoxy is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Authoxy; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 
 */

#include "AuthoxyDaemon.h"

JSBool dnsResolveInC(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);
JSBool myIpAddressInC(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);

JSRuntime *rt;
JSObject *global;
JSClass global_class =
{
  "global", 0, JS_PropertyStub,JS_PropertyStub,JS_PropertyStub,JS_PropertyStub,
  JS_EnumerateStub,JS_ResolveStub,JS_ConvertStub,JS_FinalizeStub
};

#include <curl/curl.h>

size_t collectData(void *ptr, size_t size, size_t nmemb, void *stream);

int compilePAC(JSContext *cx, char *pacURL, char *cwd)
{
  //Get the stored JS PAC functions
  char pacUtils[7000]; //file is currently 6798 characters. This will suffice plus breathing room.
  pacUtils[0] = '\0';
  
  const char pacUtilsRelativePath[] = "/../Resources/pacUtils.js";
  char pacUtilsPath[strlen(cwd) + strlen(pacUtilsRelativePath) + 1];
  pacUtilsPath[0] = '\0';
  strcpy(pacUtilsPath, cwd);
  strcat(pacUtilsPath, pacUtilsRelativePath);
  FILE *fp = fopen(pacUtilsPath, "r");
  
  if(fp==NULL)
  {
    syslog(LOG_ERR, "Unable to open pacUtils.js file. Tried to open \"%s\". Result was \"%m\".", pacUtilsPath);
    return 1;
  }

  while(!feof(fp))
  {
    char line[250];
    fgets(line, 250, fp);
    strcat(pacUtils, line);
  }
  
  fclose(fp);
  
  //Now get the PAC file
  char **scriptHdl;
  scriptHdl = (char**)malloc(sizeof(char*));
  *scriptHdl=NULL;

  CURL *myCurl = curl_easy_init();
  if(!myCurl)
  {
    syslog(LOG_ERR, "Unable to initialise curl library. Something is terribly wrong!");
    return 1;
  }
  curl_easy_setopt(myCurl, CURLOPT_NOPROGRESS, 1);	//turn off progress indication
  curl_easy_setopt(myCurl, CURLOPT_WRITEFUNCTION, collectData);
//  curl_easy_setopt(myCurl, CURLOPT_WRITEDATA, scriptHdl);
  curl_easy_setopt(myCurl, CURLOPT_FILE, scriptHdl);
  curl_easy_setopt(myCurl, CURLOPT_URL, pacURL);	//URL of pac file to download

//  syslog(LOG_NOTICE, "About to perform curl");
  curl_easy_perform(myCurl);	//download the pac file and then,
  curl_easy_cleanup(myCurl);	//clean up after ourselves
//  syslog(LOG_NOTICE, "Performed curl");
  
  if(*scriptHdl!=NULL)
  {
    char *script;
    script = *scriptHdl;
  /*
    char *script = "
      if (isPlainHostName(host)) return \"DIRECT\";
      else if (isInNet(host,\"127.0.0.1\",\"255.0.0.0\")) return \"DIRECT\";
      else if (isInNet(host,\"127.0.0.1\",\"255.0.0.0\")) return \"DIRECT\";
      else if (isInNet(host,\"134.148.0.0\",\"255.255.0.0\")) return \"DIRECT\";
      else if (isInNet(host,\"157.85.0.0\",\"255.255.0.0\")) return \"DIRECT\";
      else if (isInNet(host,\"203.1.29.0\",\"255.255.255.0\")) return \"DIRECT\";
      else if (isInNet(host,\"203.1.30.0\",\"255.255.255.0\")) return \"DIRECT\";
      else if (isInNet(host,\"203.1.32.0\",\"255.255.255.0\")) return \"DIRECT\";
      else if (isInNet(host,\"192.76.122.0\",\"255.255.255.0\")) return \"DIRECT\";
      else if (isInNet(host,\"192.82.161.0\",\"255.255.255.0\")) return \"DIRECT\";
      else if (shExpMatch(host,\"*.newcastle.edu.au\")) return \"DIRECT\";
      else if (shExpMatch(host,\"*.galegroup.com\")) return \"DIRECT\";
      else if (shExpMatch(host,\"*.gale.com\")) return \"DIRECT\";
      else if (shExpMatch(host,\"*.galenet.com\")) return \"DIRECT\";
      else if (shExpMatch(host,\"www.searchbank.com\")) return \"DIRECT\";
      else if (shExpMatch(host,\"www.ams.org\")) return \"DIRECT\";
      else if (shExpMatch(host,\"hermes.deetya.gov.au\")) return \"DIRECT\";
      else if (shExpMatch(host,\"www.blackwell-synergy.com\")) return \"DIRECT\";
      else if (shExpMatch(host,\"www.munksgaard-synergy.com\")) return \"DIRECT\";
      else     return \"PROXY vproxy-1.newcastle.edu.au:8080; PROXY vproxy-2.newcastle.edu.au:8080; DIRECT\";";
  */

    uintN lineno=1;
    jsval rval;
    if(!JS_EvaluateScript(cx, global, pacUtils, strlen(pacUtils), pacUtilsPath, lineno, &rval))
      syslog(LOG_ERR, "Failed to compile pacUtils.js file.");
    else if(!JS_EvaluateScript(cx, global, script, strlen(script), pacURL, lineno, &rval))
      syslog(LOG_ERR, "Failed to compile PAC file.");
    else
    {
      JSFunction *dnsResolveFunc  = JS_DefineFunction(cx, global, "dnsResolveInC", dnsResolveInC, 1, 0);
      JSFunction *myIpAddressFunc = JS_DefineFunction(cx, global, "myIpAddressInC", myIpAddressInC, 0, 0);

      if(!dnsResolveFunc || !myIpAddressFunc)
        syslog(LOG_ERR, "Failed to define C functions for Javascript environment.");

      free(*scriptHdl);
    }
  }
  else
  {
    syslog(LOG_ERR, "Unable to download pac file. Check the address.");
  }
  
  free(scriptHdl);
  
  return 0;
}

char* executePAC(JSContext *cx, const char *arg1, const char *arg2)
{
  jsval rval;
  JSString *jsArg1, *jsArg2;
  jsval args[2];
  JSString *str;

  jsArg1 = JS_NewStringCopyZ(cx, arg1);
  jsArg2 = JS_NewStringCopyZ(cx, arg2);
  args[0] = STRING_TO_JSVAL(jsArg1);
  args[1] = STRING_TO_JSVAL(jsArg2);

//  syslog(LOG_NOTICE, "Arg1: %s, Arg2: %s", arg1, arg2);
//  if(JS_CallFunction(cx, global, compiledScript, 2, args, &rval) == JS_FALSE)
  if(JS_CallFunctionName(cx, global, "FindProxyForURL", 2, args, &rval) == JS_FALSE)  
  {
    syslog(LOG_ERR, "Error in executing pac script");
    return NULL;
  }

  str = JS_ValueToString(cx, rval);
  char *result = (char *)malloc(JS_GetStringLength(str)+1);
  char *tempResult = JS_GetStringBytes(str);
  strcpy(result, tempResult);

  return result;
}

JSBool dnsResolveInC(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
  struct hostent *hent;
  hent = gethostbyname(JS_GetStringBytes(JSVAL_TO_STRING(argv[0])));
  if(!hent)
  {
    syslog(LOG_NOTICE, "Unable to resolve address. h-errno: %s", hstrerror(h_errno));
    JSString *result = JS_NewStringCopyZ(cx, "0.0.0.0");
    *rval = STRING_TO_JSVAL(result);
  }
  else
  {
    JSString *result = JS_NewStringCopyZ(cx, inet_ntoa(*((struct in_addr *)hent->h_addr_list[0])));
    *rval = STRING_TO_JSVAL(result);
  }
  return JS_TRUE;
}

JSBool myIpAddressInC(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
  char name[256];
  gethostname(name, 256);
  
  struct hostent *hent;
  hent = gethostbyname(name);
  if(!hent)
  {
    syslog(LOG_NOTICE, "Unable to resolve address. h-errno: %s", hstrerror(h_errno));
    JSString *result = JS_NewStringCopyZ(cx, "127.0.0.1");
    *rval = STRING_TO_JSVAL(result);
  }
  else
  {
    JSString *result = JS_NewStringCopyZ(cx, inet_ntoa(*((struct in_addr *)hent->h_addr_list[0])));
    *rval = STRING_TO_JSVAL(result);
  }
  return JS_TRUE;
}

size_t collectData(void *ptr, size_t size, size_t nmemb, void *stream)
{
  char *streamPtr=NULL;
  if(stream)
    streamPtr = *((char**)stream);
  
  if(!streamPtr)
  {
    streamPtr = (char *)malloc(nmemb*size+1*sizeof(char));
    streamPtr[0]='\0';
  }
  else
  {
    char *tempBuf;
    tempBuf = (char *)malloc((strlen(streamPtr)+1)*sizeof(char));
    tempBuf[0]='\0';
    strcpy(tempBuf, streamPtr);
    free(streamPtr);
    streamPtr = (char *)malloc((strlen(tempBuf)+1)*sizeof(char)  + nmemb*size);
    streamPtr[0]='\0';
    strcpy(streamPtr, tempBuf);
    free(tempBuf);
  }

  strncat(streamPtr, ptr, nmemb*size);

  if(stream)
    *((char**)stream) = streamPtr;
  
  return nmemb*size;
}

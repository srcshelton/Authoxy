#include <curl/curl.h>
  
  FILE *f1 = fopen(AUTHOXYD_PID_PATH, "w");
  if(f1)
    fprintf(f1, "%d", getpid());
    fclose(f1);    
  FILE *f2 = fopen(AUTHOXYD_PORT_PATH, "w");
  if(f2)
  {
    fprintf(f2, "%d", ARG_LPORT);
    fclose(f2);    
  }
  if(ARG_TEST)
    FILE *f = fopen(AUTHOXYD_TEST_PATH, "w");
    if(f)
    {
      fprintf(f, "Test connection for authoxyd has begun.\n");
      fclose(f);
    }
  int clientSocket;
  char *authStr;
  JSFunction *compiledPAC;
  if(ARG_LOGTEST != TESTING)
    syslog(LOG_NOTICE, "Authoxy has started successfully");
  else
    syslog(LOG_NOTICE, "Authoxy started in test mode. Full transcript will be written to /tmp/authoxy.test");
      
  //right, client socket is setup, the fun begins...
  int run = 1;
  while(run)	//enter an endless loop, handling requests
    if(ARG_TEST) // spawn a process to make a web request
    {
      switch(fork())
      {
        case -1:						//trouble!!
          syslog(LOG_ERR, "Fatal Error. Unable to create new process: %m");
          close(clientSocket);
          exit(EXIT_FAILURE);
        case 0:             //the child
          close(clientSocket);
          //perform a web request
          CURL *myCurl = curl_easy_init();
          if(!myCurl)
          {
            syslog(LOG_ERR, "Unable to initialise curl library. Something is terribly wrong!");
            exit(EXIT_FAILURE);
          }

          char proxyAdd[16];
          strcpy(proxyAdd, "127.0.0.1:");
          strcpy(&proxyAdd[10], ARG_LPORT_STR);
          char errorBuf[CURL_ERROR_SIZE];
          
          curl_easy_setopt(myCurl, CURLOPT_NOPROGRESS, 1);	//turn off progress indication
          curl_easy_setopt(myCurl, CURLOPT_PROXY, proxyAdd);
          curl_easy_setopt(myCurl, CURLOPT_URL, "http://www.hrsoftworks.net/TestConnection.html");
          curl_easy_setopt(myCurl, CURLOPT_ERRORBUFFER, errorBuf);
          if(curl_easy_perform(myCurl))	//download
            syslog(LOG_ERR, "Failed to fetch URL: %s", errorBuf);
          else
          {
            long resultCode;
            curl_easy_getinfo(myCurl, CURLINFO_RESPONSE_CODE, &resultCode);
            if(resultCode == 200) //Success
              syslog(LOG_NOTICE, "Successfully fetched URL.");
            else if(resultCode == 407)  //Proxy authentication required
              syslog(LOG_ERR, "Failed to fetch URL. Proxy authentication rejected.");
            else
              syslog(LOG_ERR, "Failed to fetch URL. Server returned result code: %d", resultCode);
          }
          curl_easy_cleanup(myCurl);	//clean up after ourselves
          
          exit(EXIT_SUCCESS);

        //the parent will just continue on
      }
    }
    int clientConnection;
      syslog(LOG_ERR, "Fatal Error. Unable to handle listening connection: %m");
        syslog(LOG_ERR, "Fatal Error. Unable to create new process: %m");
          performDaemonConnectionWithPACFile(compiledPAC, ARG_ADD, ARG_RPORT, clientConnection, authStr, usingNTLM, &theNTLMSettings, ARG_LOGTEST);
          performDaemonConnection(ARG_ADD, ARG_RPORT, clientConnection, authStr, usingNTLM, &theNTLMSettings, ARG_LOGTEST);
      default: //the parent, so continue on our merry way
        
        if(!ARG_TEST)
          continue;
        else  //we're testing, so wait for the child to finish its business and then quit
        {
          //Initialise result in case the parent is killed by the child and therefore doesn't return a result.
          //This happens in the successful case when the client closes the connection after completing its request.
          int result = EXIT_SUCCESS;
          wait(&result);
          if(result == EXIT_SUCCESS)
            syslog(LOG_NOTICE, "No connection problems. Check the log at %s if you experience difficulties.", AUTHOXYD_TEST_PATH);
          else
            syslog(LOG_NOTICE, "Connection failed. A log of the communication has been written to %s", AUTHOXYD_TEST_PATH);
          run = 0;  //stop running
          break;
        }
  free(authStr);
  
void performDaemonConnection(char *argAdd, int argRPort, int clientConnection, char *authStr, char usingNTLM, struct NTLMSettings *theNTLMSettingsPtr, int logging)
    syslog(LOG_NOTICE, "Couldn't open connection to proxy server: %m");
void performDaemonConnectionWithPACFile(JSFunction *compiledPAC, char *argADD, int argRPort, int clientConnection, char *authStr, char usingNTLM, struct NTLMSettings *theNTLMSettingsPtr, int logging)
    syslog(LOG_ERR, "Couldn't peek at client request for auto config script input: %m");
int bufferMatchesStringAtIndex(const char *buffer, const char *string, int index)
  int len = strlen(string);
    if(buffer[index+i] != string[i])
      return 0;
  return 1;
void logClientToServer(char *buf, int bufSize)
  mode_t oldMask = umask(0);
  FILE *f = fopen(AUTHOXYD_TEST_PATH, "a");
  if(f)
  {
    fprintf(f, "\n\n>>>\n\n");
    buf[bufSize] = '\0';
    fprintf(f, "%s", buf);
    fclose(f);
  }
  umask(oldMask);  
void logServerToClient(char *buf, int bufSize)
  mode_t oldMask = umask(0);
  FILE *f = fopen(AUTHOXYD_TEST_PATH, "a");
  if(f)
  {
    fprintf(f, "\n\n<<<\n\n");
    buf[bufSize] = '\0';
    fprintf(f, "%s", buf);
    fclose(f);
  }
  umask(oldMask);
}
    syslog(LOG_ERR, "Fatal Error: incorrect argument count for authoxyd. Ensure there are no old copies of Authoxy installed.");
  mode_t oldMask = umask(0);  //set new file mode to 0666 (read/write by everyone)
  if(f)
  {
    fprintf(f, "%d", getpid());
    fclose(f);    
  }
  if(f)
  {
    fprintf(f, "%d", ARG_LPORT);
    fclose(f);    
  }
  umask(oldMask); //set it back
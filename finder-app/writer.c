#include <syslog.h>
#include <stdio.h>
int main (int argc, char *argv[]) {

    openlog("writer", LOG_PID|LOG_CONS, LOG_USER);
    if (argc != 3){
        syslog(LOG_ERR, "Usage: %s file_path content", argv[0]); 
        return 1;
    }
    FILE *fp = fopen(argv[1], "w");
    if (fp == NULL){
        syslog(LOG_ERR, "Error opening file %s", argv[1]);
        return 1;
    }
    // check if write is successful
    if (fprintf(fp, "%s", argv[2])){
        syslog(LOG_DEBUG, "Writing %s to file %s", argv[2], argv[1]);
        return 0;
    }
    else 
    {
        syslog(LOG_ERR, "Error writing to file %s", argv[1]);
    }
    fclose(fp);
    closelog();
    return 0;  
}

typedef struct 
{
    int comPort;
    int baud;
    char mode[4];
} serialInfo;

int serialOpenPort(serialInfo* info, int comPort, int baud);
void serialClose(serialInfo* info);
void serialSend(serialInfo* info, unsigned char* buf, int len);
int serialPoll(serialInfo* info, unsigned char* buf, int bufsize);

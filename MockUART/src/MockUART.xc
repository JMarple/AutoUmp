#include "io.h"
#include <stdio.h>
#include <timer.h>
#include <stdint.h>

// Game Internals
uint8_t balls;
uint8_t strikes;
uint8_t outs;
uint8_t height;

float lastBallx;
float lastBally;

void sendGameStatus(chanend x)
{
    char output[30];

    // Format: BB_SS_OO_HH_XX.XXX_YY.YYY
    snprintf(output, 30, "%01d %01d %01d %02d %06.3f %06.3f\n",
        balls, strikes, outs, height, lastBallx, lastBally);

    for (int i = 0; i < 30; i++)
    {
        x <: output[i];

        if (output[i] == '\n') break;
    }
}

void getGameStatus(streaming chanend x)
{
    // Parse message.
    char input[30];

    for (int i = 0; i < 30; i++)
    {
       x :> input[i];
       if (input[i] == '\n') break;
    }

    sscanf(input, "%01d %01d %01d %02d %06.3f %06.3f\n",
            balls, strikes, outs, height, lastBallx, lastBally);
}

void testing(chanend x)
{
    while (1==1)
    {
        balls = 2;
        strikes = 1;
        height = 72;
        lastBallx = 10.234;
        lastBally = 24.789;

        sendGameStatus(x);
        delay_milliseconds(200);
    }
}

void recievedData(streaming chanend y)
{
    while (1==1)
    {
        //getGameStatus(y);
        //printf("DtaOut = %c\n", input);
    }
}

int main()
{
    //printf("--- UART Tester ---\n");
    chan x;
    streaming chan y;
    par
    {
        BluetoothTxThread(x);
        testing(x);
        recievedData(y);
        BluetoothRxThread(y);
    }
    return 0;
}


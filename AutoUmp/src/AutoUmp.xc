#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ov07740.h"
#include "io.h"
#include "algs.h"

extern in buffered port:32 cam1DATA;
extern in buffered port:32 cam2DATA;

#define GLB_IMAGE_ARRAY_SIZE 24
uint8_t glbBitImages[GLB_IMAGE_ARRAY_SIZE][320*240/8];

struct DenoiseLookup luTile0;

void sendToBluetoothTemporary(chanend uart1, uint8_t* unsafe buf, int length)
{ unsafe {
    for (int i = 0; i < length; i++)
    {
        uart1 <: buf[i];
    }
}}

void dataCapturingTemporaryThread(interface MasterToFloodFillInter server mtff, chanend uart1)
{ unsafe{
    int lc = 0;
    struct DenoiseLookup* unsafe lu = &luTile0;
    DenoiseInitLookup(lu);

    while (1==1)
    {
        select
        {
            case mtff.sendBitBuffer(uint8_t tmpBitBuf[], uint32_t n):
                memcpy(glbBitImages[lc++], tmpBitBuf, n*sizeof(uint8_t));

                turnOnLED6(1);
               // turnOnLED5(1);
               // turnOnLED4(1);


                //for (int i = 40; i < n; i++) glbBitImages[lc-1][i] = 0xFF;

                for (int i = 2; i < IMG_HEIGHT; i++)
                {
                    DenoiseRow(
                        (uint32_t* unsafe)&glbBitImages[lc-1][(i-2)*IMG_WIDTH/8],
                        (uint32_t* unsafe)&glbBitImages[lc-1][(i-1)*IMG_WIDTH/8],
                        (uint32_t* unsafe)&glbBitImages[lc-1][i*IMG_WIDTH/8],
                        lu);
                }

            // finish up the denoise: make the top and bottom rows 0.
            /*for (int i = 0; i < IMG_WIDTH/8; i++)
            {
                glbBitImages[lc-1][i] = 0;
                glbBitImages[lc-1][(IMG_HEIGHT-1)*IMG_WIDTH/8 + i] = 0;
            }

            // Make the left and right columns 0
            for (int i = 0; i < IMG_HEIGHT; i++)
            {
                glbBitImages[lc-1][i * IMG_WIDTH/8] = 0;
                glbBitImages[lc-1][(i+1)*IMG_WIDTH/8-1] = 0;
            }*/

                if (lc == GLB_IMAGE_ARRAY_SIZE)
                {
                    turnOnLED6(0);
                   // turnOnLED5(0);
                   // turnOnLED4(0);
                    printf("Printing!\n");
                    for (int i = 0; i < GLB_IMAGE_ARRAY_SIZE; i++)
                    {
                        delay_milliseconds(10);
                        sendToBluetoothTemporary(uart1, glbBitImages[i], 240*320/8);
                    }
                    printf("Done Printing\n");

                    lc = 0;
                }
                break;
        }
    }
}}

// "UI" tile
void Tile0(chanend bluetoothChan, interface MasterToFloodFillInter server mtff)
{
    chan bt;
    par
    {
        BluetoothThread(bt);
        dataCapturingTemporaryThread(mtff, bt);
    }
}

struct DenoiseLookup luTile1;

uint8_t gblBitImage10[320*240/8];
uint8_t gblBitImage20[320*240/8];

// "Camera" tile
void Tile1(chanend bluetoothChan, interface MasterToFloodFillInter client mtff)
{ unsafe {

    printf("Booting AutoUmp...\n");

    OV07740_InitCameras();
    OV07740_ConfigureCameras();

    streaming chan cmdStream1, cmdStream2;
    chan ffStream1, ffStream2;
    chan doStream1, doStream2; // detected objects

    struct Object objArray1[OBJECT_ARRAY_LENGTH];
    struct Object objArray2[OBJECT_ARRAY_LENGTH];

    initObjectArray(objArray1, OBJECT_ARRAY_LENGTH);
    initObjectArray(objArray2, OBJECT_ARRAY_LENGTH);

    struct Queue queue1;
    struct Queue queue2;
    queueInit(&queue1);
    queueInit(&queue2);

    // used to send information over via bluetooth
    uint8_t objInfo1[OBJECT_ARRAY_LENGTH*12];
    uint8_t objInfo2[OBJECT_ARRAY_LENGTH*12];
    for (int i = 0; i < OBJECT_ARRAY_LENGTH*12; i++)
    {
        objInfo1[i] = 0;
        objInfo2[i] = 0;
    }

    struct DenoiseLookup* unsafe lu = &luTile1;//(struct DenoiseLookup* unsafe) malloc(sizeof(struct DenoiseLookup));

    if (lu == 0) printf("Lookup table out of memory!");

    DenoiseInitLookup(lu);

    par
    {
        OV07740_MasterThread(
            cmdStream1, cmdStream2,
            ffStream1, ffStream2,
            bluetoothChan,
            (uint8_t* unsafe)objInfo1, (uint8_t* unsafe)objInfo2, mtff);

        OV07740_GatherDataThread(cmdStream1,
            (port* unsafe)&cam1DATA);

        OV07740_GatherDataThread(cmdStream2,
            (port* unsafe)&cam2DATA);

    /*    FloodFillThread(
            ffStream1,
            mtff[0],
            objArray1,
            &queue1,
            (uint8_t* unsafe)objInfo1,
            gblBitImage10, lu);

        FloodFillThread(
            ffStream2,
            mtff[1],
            objArray2,
            &queue2,
            (uint8_t* unsafe)objInfo2,
            gblBitImage20, lu);*/
    }
}}

int main()
{
    chan bluetoothChan;
    interface MasterToFloodFillInter mtff;

    par
    {
        on tile[0]: Tile0(bluetoothChan, mtff);
        on tile[1]: Tile1(bluetoothChan, mtff);
    }
    return 0;
}

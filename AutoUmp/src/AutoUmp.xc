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

void ObjectTracker(interface FloodFillToObjectInter server tile0FF2OT[4], interface FloodFillToObjectInter server tile1FF20T[4])
{
    while (1==1)
    {
        select
        {
            case tile0FF2OT[int i].sendObjects(struct Object objArray[], uint32_t n, int id):
                printf("Get Message from id = %d\n", id);
                break;

            case tile1FF20T[int i].sendObjects(struct Object objArray[], uint32_t n, int id):
                printf("Get Message from id = %d\n", id);
                break;
        }
    }
}


struct DenoiseLookup luTile0;
struct DenoiseLookup luTile1;

// "UI" tile
void Tile0(chanend bluetoothChan,
    interface MasterToFloodFillInter server tile0M2FF[4],
    interface FloodFillToObjectInter server tile1FF2OT[4])
{ unsafe {

    interface FloodFillToObjectInter tile0FF2OT[4];

    // Denoise Lookup table init
    struct DenoiseLookup* unsafe lu = &luTile0;
    if (lu == 0) printf("Lookup table out of memory!");
    DenoiseInitLookup(lu);

    par
    {
        BluetoothThread(bluetoothChan);
        FloodFillThread(tile0M2FF[0], tile0FF2OT[0], lu, 5);
        FloodFillThread(tile0M2FF[1], tile0FF2OT[1], lu, 6);
        ObjectTracker(tile0FF2OT, tile1FF2OT);
    }
}}

uint8_t gblBitImage10[320*240/8];
uint8_t gblBitImage20[320*240/8];

// "Camera" tile
void Tile1(
    chanend bluetoothChan,
    interface MasterToFloodFillInter client til0M2FF[4],
    interface FloodFillToObjectInter client tile1FF2TO[4])
{ unsafe {

    printf("Booting AutoUmp...\n");

    OV07740_InitCameras();
    OV07740_ConfigureCameras();

    printf("Starting AutoUmp...\n");

    streaming chan cameraStream[2];

    // Denoise lookup table init
    struct DenoiseLookup* unsafe lu = &luTile1;
    if (lu == 0) printf("Lookup table out of memory!");
    DenoiseInitLookup(lu);

    interface MasterToFloodFillInter localM2FF[4];

    par
    {
        OV07740_MasterThread(
            cameraStream, localM2FF, til0M2FF);

        OV07740_GatherDataThread(cameraStream[0],
            (port* unsafe)&cam1DATA);

        OV07740_GatherDataThread(cameraStream[1],
            (port* unsafe)&cam2DATA);

        FloodFillThread(localM2FF[0], tile1FF2TO[0], lu, 1);
        FloodFillThread(localM2FF[1], tile1FF2TO[1], lu, 2);
        FloodFillThread(localM2FF[2], tile1FF2TO[2], lu, 3);
        FloodFillThread(localM2FF[3], tile1FF2TO[3], lu, 4);
    }
}}

int main()
{
    chan bluetoothChan;
    interface MasterToFloodFillInter M2FF[4];
    interface FloodFillToObjectInter FF2OT[4];

    par
    {
        on tile[0]: Tile0(bluetoothChan, M2FF, FF2OT);
        on tile[1]: Tile1(bluetoothChan, M2FF, FF2OT);
    }
    return 0;
}

#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string.h>
#include "ov07740.h"
#include "io.h"
#include "floodFillAlg.h"
#include "game.h"

extern in buffered port:32 cam1DATA;
extern in buffered port:32 cam2DATA;

struct DenoiseLookup luTile0;

void ObjectTracker(
    interface ObjectTrackerToGameInter client ot2g,
    interface FloodFillToObjectInter server tile0FF2OT[4],
    interface FloodFillToObjectInter server tile1FF2OT[4])
{
    int loopCount = 0;
    uint8_t buffer[320*240/8];
    struct Object objArrayTmp[250];

    while(1==1)
    {
        select
        {
            case tile0FF2OT[int i].sendObjects(struct Object objArray[], uint32_t n, uint8_t bitBuffer[], uint32_t m, int id):
                if (i != 0) break;

                loopCount++;

                if(loopCount % 1 == 0)
                {
                    for(int i = 0; i < 250; i++)
                    {
                        objArrayTmp[i] = objArray[i];
                    }
                    memset(buffer, 0, 3000);
                    packObjects(objArrayTmp, buffer, n);

                    ot2g.forwardBuffer(buffer, 250*9);
                    //btInter.sendBuffer(buffer, 250*9);

                }
                break;

            case tile1FF2OT[int i].sendObjects(struct Object objArray[], uint32_t n, uint8_t bitBuffer[], uint32_t m, int id):
                break;
        }
    }
}

void sendToBluetoothTemporary(chanend uart1, uint8_t* unsafe buf, int length)
{ unsafe {
    for (int i = 0; i < length; i++)
    {
        uart1 <: buf[i];
    }
}}

struct DenoiseLookup luTile0;
struct DenoiseLookup luTile1;

// "UI" tile
void Tile0(
    interface MasterToFloodFillInter server tile0M2FF[4],
    interface FloodFillToObjectInter server tile1FF2OT[4])
{ unsafe {

    interface FloodFillToObjectInter tile0FF2OT[4];
    interface BluetoothInter btInter;
    interface ObjectTrackerToGameInter ot2g;

    // Denoise Lookup table init
    struct DenoiseLookup* unsafe lu = &luTile0;
    DenoiseInitLookup(lu);

    par
    {
        BluetoothThread(btInter);
        FloodFillThread(tile0M2FF[0], tile0FF2OT[0], lu, 3);
        FloodFillThread(tile0M2FF[1], tile0FF2OT[1], lu, 4);
        FloodFillThread(tile0M2FF[2], tile0FF2OT[2], lu, 5);
        FloodFillThread(tile0M2FF[3], tile0FF2OT[3], lu, 6);
        ObjectTracker(/*btInter*/ot2g, tile0FF2OT, tile1FF2OT);
        GameThread(ot2g, btInter);
    }
}}

uint8_t gblBitImage10[320*240/8];
uint8_t gblBitImage20[320*240/8];

// "Camera" tile
void Tile1(
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
    }
}}

int main()
{
    interface MasterToFloodFillInter M2FF[4];
    interface FloodFillToObjectInter FF2OT[4];

    par
    {
        on tile[0]: Tile0(M2FF, FF2OT);
        on tile[1]: Tile1(M2FF, FF2OT);
    }
    return 0;
}

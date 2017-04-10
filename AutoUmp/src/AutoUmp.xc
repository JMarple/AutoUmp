#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ov07740.h"
#include "io.h"
#include "floodFillAlg.h"
#include "objectTrackerAlg.h"
#include "gameAlg.h"

extern in buffered port:32 cam1DATA;
extern in buffered port:32 cam2DATA;

struct DenoiseLookup luTile0;

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

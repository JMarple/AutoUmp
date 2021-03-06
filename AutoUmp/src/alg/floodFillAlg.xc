#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "floodFillAlg.h"
#include "detect_objects.h"

// bitBuffer is an entire bit image
// objCenters will be filled with objCenters ready to be sent over UART
int FloodFillMain(
    uint8_t* unsafe bitBuffer,
    struct Object* objArray,
    struct Queue* queue,
    struct DenoiseLookup* unsafe lu)
{ unsafe {

    timer t;
    uint32_t st, ed, wait;
    t :> st;
    wait = st + 4500000;

    for (int i = 2; i < IMG_HEIGHT; i++)
    {
        DenoiseRow(
            (uint32_t* unsafe)&bitBuffer[(i-2)*IMG_WIDTH/8],
            (uint32_t* unsafe)&bitBuffer[(i-1)*IMG_WIDTH/8],
            (uint32_t* unsafe)&bitBuffer[i*IMG_WIDTH/8],
            lu);
    }

    // finish up the denoise: make the top and bottom rows 0.
    for (int i = 0; i < IMG_WIDTH/8; i++)
    {
        bitBuffer[i] = 0;
        bitBuffer[(IMG_HEIGHT-1)*IMG_WIDTH/8 + i] = 0;
    }

    // Make the left and right columns 0
    for (int i = 0; i < IMG_HEIGHT; i++)
    {
        bitBuffer[i * IMG_WIDTH/8] = 0;
        bitBuffer[(i+1)*IMG_WIDTH/8-1] = 0;
    }

    // copy data
    // operate on new data
    //uint8_t newBitBuffer[IMG_HEIGHT*IMG_WIDTH/8];
    //memcpy(newBitBuffer, bitBuffer, IMG_HEIGHT*IMG_WIDTH/8);

    // actual floodfill
    int32_t numObjects = scanPic(objArray, queue, bitBuffer);
    if (numObjects == -1) // we hit more objects than we had space for and ended floodfill early
    {
        // TODO: handle exception
        numObjects = OBJECT_ARRAY_LENGTH;
    }
    t :> ed;

    mergeObjects(objArray, numObjects);


    if ((ed-st) > 4500000)
    {
        //printf("CRITICAL: Taking too long to run floodfill = %d\n", (ed-st));
        return -1;
    }


    t when timerafter(st) :> void;

    //int numObjects = 0;
    return numObjects;
}}


void FloodFillThread(
    interface MasterToFloodFillInter server mtff,
    interface FloodFillToObjectInter client ff2ot,
    struct DenoiseLookup* unsafe lu, int num)
{ unsafe {

    uint8_t bitBuffer[320*240/8];
    struct Queue queue;
    queueInit(&queue);
    struct Object objArray[OBJECT_ARRAY_LENGTH];

    while (1==1)
    {
        select {
            case mtff.sendBitBuffer(uint8_t tmpBitBuf[], uint32_t n):
                memcpy(bitBuffer, tmpBitBuf, n*sizeof(uint8_t));
                break;
        }

        int numObjects = FloodFillMain((uint8_t* unsafe)bitBuffer, objArray, &queue, lu);

        ff2ot.sendObjects(objArray, numObjects, bitBuffer, 320*240/8, num);
    }
}}


#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "algs.h"
#include "detect_objects.h"

uint8_t lookup32[32] = {
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 0, 0, 1,
        0, 0, 0, 1, 0, 0, 0, 1,
        0, 1, 1, 1, 0, 1, 1, 1};

// bitBuffer is an entire bit image
// objCenters will be filled with objCenters ready to be sent over UART
void FloodFill(uint8_t* unsafe bitBuffer, struct Object* objArray, struct Queue* queue, uint8_t* unsafe objCenters, uint8_t* unsafe objBoxes)
{ unsafe {
    for (int i = 2; i < IMG_HEIGHT; i++)
    {
        DenoiseRow(
                (uint32_t* unsafe)&bitBuffer[(i-2)*IMG_WIDTH/8],
                (uint32_t* unsafe)&bitBuffer[(i-1)*IMG_WIDTH/8],
                (uint32_t* unsafe)&bitBuffer[i*IMG_WIDTH/8]);
    }
    for (int i = 0; i < IMG_WIDTH/8; i++)
    {
        bitBuffer[i] = 0;
        bitBuffer[(IMG_HEIGHT-1)*IMG_WIDTH/8 + i] = 0;
    }

    // copy data
    // operate on new data
    uint8_t newBitBuffer[IMG_HEIGHT*IMG_WIDTH/8];
    for (int i = 0; i < IMG_HEIGHT*IMG_WIDTH/8; i++)
    {
        newBitBuffer[i] = bitBuffer[i];
    }

    int32_t numObjects = scanPic(objArray, queue, newBitBuffer);
    if(numObjects == -1) // we hit more objects than we had space for and ended floodfill early
    {
        // TODO: handle exception
        numObjects = OBJECT_ARRAY_LENGTH;
    }

    /*struct Object fakeArr[128];
    initObjectArray(fakeArr, 128);
    struct Object fakeArrAfter[128];
    initObjectArray(fakeArrAfter, 128);
    for(int i = 0; i < 128; i++)
    {
        fakeArr[i].centX = i;
        fakeArr[i].centY = i+8;
        if(i == 127)
        {
            fakeArr[i].centX = 65535;
            fakeArr[i].centY = 65535;
        }
    }
    packCenters(fakeArr, objCenters, 128);*/
    /*unpackCenters(fakeArrAfter, objCenters, 128*4);

    printCenters(fakeArrAfter, 128);*/


    computeCenters(objArray, numObjects);
    packCenters(objArray, objCenters, numObjects);

    //printf("--------- PIC --------\n");
    //struct Object smallArr[51];
    //initObjectArray(smallArr, 51);
    //unpackCenters(smallArr, objCenters, 51*4);
    //printCenters(smallArr, 50);
    //printf("numObjects: %i\n", numObjects);
}}

void FloodFillThread(chanend stream, struct Object* objArray, struct Queue* queue, uint8_t* unsafe objCenters, uint8_t* unsafe objBoxes)
{ unsafe {
    uint32_t start, end;
    timer t;

    while (1==1)
    {
        // Blocking statement that recieves a bit image
        uint32_t* unsafe bitBuffer;
        stream :> bitBuffer;

        t :> start;

        FloodFill((uint8_t* unsafe)bitBuffer, objArray, queue, objCenters, objBoxes);

        t :> end;
        printf("Clock ticks (@100Mhz) = %d\n", (end - start));
    }
}}

void DenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot)
{ unsafe {

    // init
    uint32_t topWord  = 0;
    uint32_t curWord  = 0;
    uint32_t botWord  = 0;
    uint32_t topBit   = 0;
    uint32_t curBit   = 0;
    uint32_t botBit   = 0;
    uint32_t rightBit = 0;
    uint32_t leftBit  = 0;
    uint32_t result   = 0;
    uint32_t outWord  = 0;

    for (int i = 0; i < 10; i++)
    {
        topWord = top[i];
        curWord = cur[i];
        botWord = bot[i];
        for (int k = 0; k < 32; k++)
        {
            rightBit = curWord & 0x1;

            // compute result
            result = topBit + botBit + leftBit + rightBit;
            result = ((result > 2) * curBit) << 31;

            outWord |= result;

            // shift words
            curWord = curWord >> 1;

            if(k == 0 && i != 0)
            {
                cur[i-1] = outWord;
                outWord = 0;
            }

            outWord = outWord >> 1;

            // shift bits
            leftBit = curBit;
            curBit  = rightBit;

            topBit  = topWord & 0x1;
            botBit  = botWord & 0x1;

            // shift words
            topWord = topWord >> 1;
            botWord = botWord >> 1;
        }
    }
    cur[9] = outWord;
}}




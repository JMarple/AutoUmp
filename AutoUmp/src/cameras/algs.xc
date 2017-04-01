#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "algs.h"
#include "detect_objects.h"
#include "find_balls.h"

// bitBuffer is an entire bit image
// objCenters will be filled with objCenters ready to be sent over UART
void FloodFill(
    uint8_t* unsafe bitBuffer,
    struct Object* objArray,
    struct Queue* queue,
    struct DenoiseLookup* unsafe lu)
{ unsafe {

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
    uint8_t newBitBuffer[IMG_HEIGHT*IMG_WIDTH/8];
    for (int i = 0; i < IMG_HEIGHT*IMG_WIDTH/8; i++)
    {
        newBitBuffer[i] = bitBuffer[i];
    }

    // actual floodfill
    int32_t numObjects = scanPic(objArray, queue, newBitBuffer);
    if(numObjects == -1) // we hit more objects than we had space for and ended floodfill early
    {
        // TODO: handle exception
        numObjects = OBJECT_ARRAY_LENGTH;
    }

    //findCenters
    computeCenters(objArray, numObjects);
    //packObjects(objArray, objInfo, numObjects);

    /*struct Object afterArr[250];
    initObjectArray(afterArr, 250);

    unpackObjects(afterArr, objInfo, 250*12);
    for(int i = 0; i < 250; i++)
    {
        printf("%i %i\n", afterArr[i].minX, afterArr[i].maxX);
    }*/

    /*struct Object fakeArr[250];
    initObjectArray(fakeArr, 250);
    for(int i = 0; i < 50; i++)
    {
        fakeArr[i].minX = i;
        fakeArr[i].maxX = i+1;
        fakeArr[i].minY = i+2;
        fakeArr[i].maxY = i+3;
        fakeArr[i].centX = i+4;
        fakeArr[i].centY = i+5;
    }
    packObjects(fakeArr, objInfo, 250);
    for(int i = 0; i < 250*12; i++)
    {
       if(i % 12 == 0 && i != 0)
       {
           printf("\n");
       }
       printf("%x ", objInfo[i]);
    }

    struct Object fakeArrAfter[250];
    initObjectArray(fakeArrAfter, 250);
    unpackObjects(fakeArrAfter, objInfo, OBJECT_ARRAY_LENGTH*12);*/
    /*for(int i = 0; i < OBJECT_ARRAY_LENGTH; i++)
    {
        if(fakeArrAfter[i].centX > IMG_WIDTH || fakeArrAfter[i].centY > IMG_HEIGHT)
        {
            printf("exceeded. centX %i, centY %i\n", fakeArrAfter[i].centX, fakeArrAfter[i].centY);
        }
    }*/

    //printObjectArray(fakeArrAfter, OBJECT_ARRAY_LENGTH);


    //printf("--------- PIC --------\n");
    //struct Object smallArr[51];
    //initObjectArray(smallArr, 51);
    //unpackCenters(smallArr, objCenters, 51*4);
    //printCenters(smallArr, 50);
    //printf("numObjects: %i\n", numObjects);
}}


static void _DenoiseInitElement(uint8_t* output, uint8_t cur, uint8_t bot, uint8_t top)
{
    uint8_t result = 0;

    for (int i = 0; i < 4; i++)
    {
        int count = 0;
        int curBit = (cur & 0b000010) > 0;

        count += (cur & 0b000001);
        count += (cur & 0b000100) > 0;
        count += (top & 0b0001);
        count += (bot & 0b0001);

        //printf("count=%d ", count);
        if (count > 2) result |= ((1*curBit) << i);

        top >>= 1;
        bot >>= 1;
        cur >>= 1;
    }

    //printf("%x %x %x, %x\n", cur, bot, top, result);
    *output = result;
}

void DenoiseInitLookup(struct DenoiseLookup* unsafe lu)
{ unsafe {
    for (int cur = 0; cur < 64; cur++)
    {
        for (int bot = 0; bot < 16; bot++)
        {
            for (int top = 0; top < 16; top++)
            {
                _DenoiseInitElement(
                    &lu->cur[cur].bot[bot].top[top],
                    cur, bot, top);
            }
        }
    }

    // Example
    //printf("Example = %d\n", lu->cur[0].bot[0].top[0]);
}}


void FloodFillThread(
    interface MasterToFloodFillInter server mtff,
    interface FloodFillToObjectInter client ff2ot,
    struct DenoiseLookup* unsafe lu, int num)
{ unsafe {


    uint8_t bitBuffer[320*240/8];
    struct Queue queue;
    struct Object objArray[OBJECT_ARRAY_LENGTH];

    while (1==1)
    {
        select {
            case mtff.sendBitBuffer(uint8_t tmpBitBuf[], uint32_t n):
                memcpy(bitBuffer, tmpBitBuf, n*sizeof(uint8_t));
                break;
        }

        // Do FloodFill Here
        //FloodFill((uint8_t* unsafe)bitBuffer, objArray, &queue, lu);

        ff2ot.sendObjects(objArray, OBJECT_ARRAY_LENGTH, num);
    }
}}
/*void DenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot,
    struct DenoiseLookup* unsafe lu)
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
}}*/

void DenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot,
    struct DenoiseLookup* unsafe lu)
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
        //printf("Row %d, %x %x %x\n", i, top[i], cur[i], bot[i]);
    }

    curWord = (cur[0] << 1);
    topWord = top[0];
    botWord = bot[0];

    for (int i = 0; i < 320; i+=4)
    {
        int idx = i / 32;
        if (i % 32 == 8)
        {
            uint32_t tmp = (cur[idx] & 0xF8000000) >> 7;
            //printf("imod32=4, %x %x\n", tmp, curWord);
            curWord |= tmp;
            //printf("curNow = %x\n", curWord);
        }
        else if (i % 32 == 28)
        {
            //printf("CurBefore=%x\n", curWord);
            curWord |= (cur[idx+1] << 5);
            //printf("CurAfter=%x\n", curWord);
            //printf("Loaded = %x %x %x\n", curWord, topWord, botWord);
        }

        uint32_t res = lu->cur[curWord & 0x3F].bot[botWord & 0xF].top[topWord & 0xF];
        //printf("c=%03d %08x, %x, %x %x %x\n", i, curWord, res, curWord& 0x3F, botWord& 0xF, topWord& 0xF);

        res <<= 28;
        outWord |= res;

        topWord >>= 4;
        botWord >>= 4;

        // Save outWord
        if (i % 32 == 28)
        {
            cur[idx] = outWord;
            //printf("Out = %x\n", outWord);
            topWord = top[idx];
            botWord = bot[idx];
        }

        outWord >>= 4;
        curWord >>= 4;
    }
}}


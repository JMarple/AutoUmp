#include <stdio.h>
#include <stdint.h>
#include <stdlib.h> // for abs()
#include "detect_objects.h"
#include "algs.h"

void objectOverwrite(struct Object* obj, uint16_t id, uint8_t isBall, uint32_t minX, uint32_t maxX, uint32_t minY, uint32_t maxY)
{
    obj->id = id; // no object
    obj->isBall = isBall;
    obj->minX = minX; // goes along width/columns of image
    obj->minY = minY; // goes down height/rows of image
    obj->maxX = maxX;
    obj->maxY = maxY;
}

int32_t scanPic(struct Object* objArray, struct Queue* q, uint8_t* unsafe bitPicture)
{ unsafe {
    int32_t objectId  = -1;
    uint32_t byteIndex =  IMG_WIDTH/8; // the current byte we're looking at. Remember, there are 8 pixels in here.
    uint8_t  bitVal    =  0;
    //uint32_t curWord   =  0;

    // the line below behaves unexpectedly. If you have a uint8_t array[4], instead of pointing to the equivalent of
    // array[0] array[1] array[2] array[3]
    // it points to
    // array[3] array[2] array[1] array[0]
    // uint32_t* fourCurrent = &bitPicture[byteIndex]; // want to examine 4 bytes at a time to speed through the 0s.

    while(byteIndex < (IMG_HEIGHT-1)*IMG_WIDTH/8) // TODO: Optimize by passing bitPicture as a 242 x 322 image. Will require "sweeping changes"
    {
       // curWord = (uint32_t)bitPicture[byteIndex];
        if(bitPicture[byteIndex]==0)
        {
            byteIndex++;
            //fourCurrent = &bitPicture[byteIndex];
            continue;
        }
        else // got something to look at
        {
            for(int i = 0; i < 8; i++)
            {
                bitVal = getBitInByte(bitPicture[byteIndex], i); // data is arranged 7 6 5 4 3 2 2 1 0 for each byte.

                // if temp == 0, do nothing and move on
                if(bitVal>0)
                {
                    objectId++;
                    uint32_t bitIndex = byteIndex*8 + i;
                    queueEnqueue(q, bitIndex); //push the bit index to the queue
                    if(objectId >= OBJECT_ARRAY_LENGTH)
                    {
                        return -1;
                    }
                    else
                    {
                        // after the first frame, objArray holds old data. So we need to overwrite that data with what's new.
                        objectOverwrite(
                                &objArray[objectId],
                                objectId,
                                -1,                    // isBall
                                bitIndex % IMG_WIDTH,  // minX
                                bitIndex % IMG_WIDTH,  // maxX
                                bitIndex / IMG_WIDTH,  // minY
                                bitIndex / IMG_WIDTH); // maxY

                        floodFill(bitPicture, q, &objArray[objectId]);
                    }
                }
            }
            byteIndex++;
            //fourCurrent = &bitPicture[byteIndex];
        }
    }

    return objectId+1;
}}

void floodFill(uint8_t* unsafe bitPicture, struct Queue* q, struct Object* currentObject)
{ unsafe {
    while(!queueIsEmpty(q))
    {
        uint32_t indexBit = queueDequeue(q);

        // Necessary because a pixel might get added to queue at least twice
        if(getBitInPic(bitPicture, indexBit)==0)
        {
            continue;
        }
        uint32_t indexAbove = indexBit-IMG_WIDTH;
        uint32_t indexBelow = indexBit+IMG_WIDTH;
        uint32_t indexLeft  = indexBit-1;
        uint32_t indexRight = indexBit+1;

        setBitInPic(bitPicture, indexBit, 0);
        uint8_t bitAbove = getBitInPic(bitPicture, indexAbove);
        uint8_t bitBelow = getBitInPic(bitPicture, indexBelow);
        uint8_t bitLeft  = getBitInPic(bitPicture, indexLeft);
        uint8_t bitRight = getBitInPic(bitPicture, indexRight);

        if(bitAbove > 0) // first check to ensure that we don't look at values outside our range
        {
            queueEnqueue(q, indexAbove);
            updateObject(currentObject, indexAbove);
        }

        if(bitBelow > 0) // first check to ensure that we don't look at values outside our range
        {
            queueEnqueue(q, indexBelow);
            updateObject(currentObject, indexBelow);
        }

        if((indexBit % IMG_WIDTH > 0) && (bitLeft > 0)) // first check to ensure we have an actual "left" pixel to look at
        {
            queueEnqueue(q, indexLeft);
            updateObject(currentObject, indexLeft);
        }

        if((indexBit % IMG_WIDTH < IMG_WIDTH-1) && (bitRight > 0)) // first check to ensure we have an actual "right" pixel to look at
        {
            queueEnqueue(q, indexRight);
            updateObject(currentObject, indexRight);
        }
    }
}}

void updateObject(struct Object* object, uint32_t bitIndex)
{
    uint16_t newY = bitIndex / IMG_WIDTH; // goes along rows/height of image
    uint16_t newX = bitIndex % IMG_WIDTH; // goes along columns/width of image

    if(newX < object->minX)
    {
        object->minX = newX;
    }

    if(newX > object->maxX)
    {
        object->maxX = newX;
    }

    if(newY < object->minY)
    {
        object->minY = newY;
    }

    if(newY > object->maxY)
    {
        object->maxY = newY;
    }
}

// computes the center of a particular object
void computeCenter(struct Object* object)
{
    object->centX = (object->minX + object->maxX)/2;
    object->centY = (object->minY + object->maxY)/2;
    object->distanceFromCenter = abs(object->centX - IMG_WIDTH/2);
}

// computes center for an array of objects
void computeCenters(struct Object* objectArray, int32_t length)
{
    for (int i = 0; i < length; i++)
    {
        computeCenter(&objectArray[i]);
    }
}

void getTwoCenters(struct Center* centerPair, struct Object* objectArray, struct Center* centerArray, uint16_t length)
{
    uint8_t numCents = 0;
    uint8_t i = 0;
    while((objectArray[i].id != EMPTY_OBJECT_ID) && (i < length))
    {
        if(objectArray[i].isBall && numCents < 2)
        {
            centerPair[numCents] = centerArray[i];
            numCents++;
        }
        i++;
    }
}

// marks each object: is it a ball or not?
int32_t filterBalls(struct Object* objectArray, uint16_t length)
{
    uint8_t i = 0;
    int32_t numBalls = 0;
    while((objectArray[i].id != EMPTY_OBJECT_ID) && (i < length))
    {
        // if object is smaller than possible for our ball
        if(objectArray[i].maxX - objectArray[i].minX < 5 ||
            objectArray[i].maxY - objectArray[i].minY < 5)
        {
            objectArray[i].isBall = 0;
        }

        // if the object is on the edge of the image
        // (where edge is defined as 2 pixel width surrounding edge)
        else if(objectArray[i].minX < 2 || objectArray[i].minY < 2 ||
            objectArray[i].maxX > IMG_WIDTH-3 || objectArray[i].maxY > IMG_HEIGHT-3)
        {
            objectArray[i].isBall = 0;
        }

        else // it's a ball
        {
            objectArray[i].isBall = 1;
            numBalls++;
        }
        i++;
    }
    return numBalls;
}

void objectInit(struct Object* obj)
{
    obj->id = EMPTY_OBJECT_ID; // no object
    obj->isBall = -1;
    obj->minX = IMG_WIDTH; // goes along width/columns of image
    obj->minY = IMG_HEIGHT; // goes down height/rows of image
    obj->maxX = 0;
    obj->maxY = 0;
    obj->centX = 0;
    obj->centY = 0;
    obj->distanceFromCenter = 0;
}

void initObjectArray(struct Object* objArray, uint16_t length)
{
    for (int i = 0; i < length; i ++)
    {
        objArray[i].id = EMPTY_OBJECT_ID;
        objArray[i].isBall = -1;
        objArray[i].minX = IMG_WIDTH;
        objArray[i].maxX = 0;
        objArray[i].minY = IMG_HEIGHT;
        objArray[i].maxY = 0;
        objArray[i].centX = 0;
        objArray[i].centY = 0;
        objArray[i].distanceFromCenter = 0;
    }
}

void packBoundingBoxes(
    struct Object* objArray,
    uint8_t* unsafe buffer,
    int32_t numObjects)
{ unsafe {
    for(int i = 0; i < numObjects; i++)
        {
            uint8_t xMinLower = objArray[i].minX & 0xFF;
            uint8_t xMinUpper = objArray[i].minX >> 8;
            uint8_t xMaxLower = objArray[i].maxX & 0xFF;
            uint8_t xMaxUpper = objArray[i].maxX >> 8;
            uint8_t yMinLower = objArray[i].minY & 0xFF;
            uint8_t yMinUpper = objArray[i].minY >> 8;
            uint8_t yMaxLower = objArray[i].maxY & 0xFF;
            uint8_t yMaxUpper = objArray[i].maxY >> 8;

            buffer[i*4]     = xMinLower;
            buffer[i*4 + 1] = xMinUpper;
            buffer[i*4 + 2] = xMaxLower;
            buffer[i*4 + 3] = xMaxUpper;
            buffer[i*4 + 4] = yMinLower;
            buffer[i*4 + 5] = yMinUpper;
            buffer[i*4 + 6] = yMaxLower;
            buffer[i*4 + 7] = yMaxUpper;
        }
        if(numObjects < 250) // send a code: we're done with our objects
        {
            for(int i = 0; i < 4; i++)
            {
                buffer[numObjects*4 + i] = 0xFF;
            }
        }
}}

// pack the center data to be used for sending over uart
void packCenters(
    struct Object* objArray,
    uint8_t* unsafe buffer,
    int32_t numObjects)
{ unsafe {
    for(int i = 0; i < numObjects; i++)
    {
        uint8_t xLower = objArray[i].centX & 0xFF;
        uint8_t xUpper = objArray[i].centX >> 8;
        uint8_t yLower = objArray[i].centY & 0xFF;
        uint8_t yUpper = objArray[i].centY >> 8;

        buffer[i*4] = xLower;
        buffer[i*4 + 1] = xUpper;
        buffer[i*4 + 2] = yLower;
        buffer[i*4 + 3] = yUpper;
    }
    if(numObjects < 250) // send a code: we're done with our objects
    {
        for(int i = 0; i < 4; i++)
        {
            buffer[numObjects*4 + i] = 0xFF;
        }
    }
}}

int32_t unpackCenters(
    struct Object* objArray,
    uint8_t* unsafe buffer,
    uint16_t bufferLength)
{ unsafe {
    for(int i = 0; i < bufferLength; i+=4)
    {
        uint8_t xLower = buffer[i];
        uint8_t xUpper = buffer[i+1];
        uint8_t yLower = buffer[i+2];
        uint8_t yUpper = buffer[i+3];

        uint16_t centX = (xUpper << 8) | xLower;
        uint16_t centY = (yUpper << 8) | yLower;

        if(centX == 65535) // that's our cue -- we've hit our last object
        {
            return i/4+1; // num objects
            break;
        }

        objArray[i/4].centX = centX;
        objArray[i/4].centY = centY;
    }
    return bufferLength/4; // num objects
}}


void printObjectArray(struct Object* objArray, uint16_t length)
{
    uint16_t i = 0;
    while((i < length) && (objArray[i].id != EMPTY_OBJECT_ID))
    {
        printf("id: %i; minX: %i; maxX: %i; minY: %i; maxY: %i; centX: %i; centY: %i \n",
            objArray[i].id,
            objArray[i].minX,
            objArray[i].maxX,
            objArray[i].minY,
            objArray[i].maxY,
            objArray[i].centX,
            objArray[i].centY);
        i++;
    }
    printf("\n");
}

void printCenters(struct Object* objArray, uint16_t length)
{
    uint16_t i = 0;
    while((i < length) && (objArray[i].centX != 65535))
    {
        printf("centX: %x; centY: %x \n",
            objArray[i].centX,
            objArray[i].centY);
        i++;
    }
    printf("\n");
}


// bitLoc is the bit location. 7 for MSB, 0 for LSB, etc.
uint8_t getBitInByte(uint8_t byte, uint32_t bitLoc)
{
    byte = byte << (7-bitLoc);
    byte = byte >> 7;

    return byte;
}

// given a certain bitIndex, get that bit (stored in a byte).
// so a bitIndex of 4 will get the 4th bit.
uint8_t getBitInPic(uint8_t* unsafe bitPicture, uint32_t bitIndex)
{ unsafe {
    uint8_t val; // return value
    uint32_t byteIndex = bitIndex/8;
    uint32_t bitNum = bitIndex % 8;

    // val = getBitInByte(bitPicture[byteIndex], 7-bitNum); // this is for when bytes were arranged 0 1 2 3 4 5 6 7 instead of 7 6 ...
    val = getBitInByte(bitPicture[byteIndex], bitNum);
    return val;
}}


// bitLoc is the bit location. 7 for MSB, 0 for LSB, etc.
int8_t setBitInByte(uint8_t* unsafe byte, uint8_t bitLoc, uint8_t bitVal)
{ unsafe {
    /*if(bitVal > 1 || bitLoc > 7)
    {
        return FUNC_ERROR;
    }*/
    //http://stackoverflow.com/questions/47981/how-do-you-set-clear-and-toggle-a-single-bit-in-c-c
    *byte = (*byte & ~(1 << bitLoc)) | (bitVal << bitLoc);

    return 0;
}}

// given a certain bitIndex, set that bit to either 0 or 1.
int8_t setBitInPic(uint8_t* unsafe bitPicture, uint32_t bitIndex, uint8_t val)
{ unsafe {
    /*if(val > 1 || bitIndex >= IMG_WIDTH*IMG_HEIGHT)
    {
        return FUNC_ERROR;
    }*/
    uint32_t byteIndex = bitIndex/8;
    uint8_t bitNum = bitIndex % 8;

    //setBitInByte(&bitPicture[byteIndex], 7-bitNum, val); // this is for when bytes were arranged 0 1 2 3 4 5 6 7 instead of 7 6 ...
    setBitInByte(&bitPicture[byteIndex], bitNum, val);

    return 0;
}}


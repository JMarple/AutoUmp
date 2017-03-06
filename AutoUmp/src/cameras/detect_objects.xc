#include <stdio.h>
#include <stdint.h>
#include <stdlib.h> // for abs()
#include "detect_objects.h"
#include "algs.h"

void objectInit(struct Object* obj)
{
    obj->id = EMPTY_OBJECT_ID; // no object
    obj->isBall = -1;
    obj->minX = IMG_HEIGHT*IMG_WIDTH+1; // goes along width/columns of image
    obj->minY = IMG_HEIGHT*IMG_WIDTH+1; // goes down height/rows of image
    obj->maxX = 0;
    obj->maxY = 0;
}

uint16_t scanPic(struct Object* objArray, struct Queue* q, uint8_t* unsafe bitPicture, uint32_t width, uint32_t height)
{ unsafe {
    uint16_t objectId  = -1;
    uint32_t byteIndex =  0; // the current byte we're looking at. Remember, there are 8 pixels in here.
    uint8_t  bitVal    =  0;

    // the line below behaves unexpectedly. If you have a uint8_t array[4], instead of pointing to the equivalent of
    // array[0] array[1] array[2] array[3]
    // it points to
    // array[3] array[2] array[1] array[0]
    // uint32_t* fourCurrent = &bitPicture[byteIndex]; // want to examine 4 bytes at a time to speed through the 0s.

    while(byteIndex < height*width/8)
    {
        if(bitPicture[byteIndex]==0)
        {
            byteIndex++;
            //fourCurrent = &bitPicture[byteIndex];
            continue;
        }
        else // got something to look at
        {
            for(int i = 7; i >= 0; i--)
            {
                bitVal = getBitInByte(bitPicture[byteIndex], i);

                // if temp == 0, do nothing and move on
                if(bitVal>0)
                {
                    objectId++;
                    queueEnqueue(q, byteIndex*8 + (7-i)); //push the bit index to the queue
                    objArray[objectId % OBJECT_ARRAY_LENGTH].id = objectId;
                    updateObject(&objArray[objectId % OBJECT_ARRAY_LENGTH], byteIndex*8 + (7-i), width, height);
                    floodFill(bitPicture, q, &objArray[objectId % OBJECT_ARRAY_LENGTH], width, height);
                }
            }
            byteIndex++;
            //fourCurrent = &bitPicture[byteIndex];
        }
    }

    return objectId;
}}

void floodFill(uint8_t* unsafe bitPicture, struct Queue* q, struct Object* currentObject, uint32_t width, uint32_t height)
{ unsafe {
    while(!queueIsEmpty(q))
    {
        uint32_t indexBit = queueDequeue(q);
        if(getBitInPic(bitPicture, indexBit)==0) // idk why this is necessary, but it makes it work
        {
            continue;
        }
        uint32_t indexAbove = indexBit-width;
        uint32_t indexBelow = indexBit+width;
        uint32_t indexLeft  = indexBit-1;
        uint32_t indexRight = indexBit+1;

        setBitInPic(bitPicture, indexBit, 0);
        uint8_t bitAbove = getBitInPic(bitPicture, indexAbove);
        uint8_t bitBelow = getBitInPic(bitPicture, indexBelow);
        uint8_t bitLeft  = getBitInPic(bitPicture, indexLeft);
        uint8_t bitRight = getBitInPic(bitPicture, indexRight);

        if((indexBit > width) && (bitAbove > 0)) // first check to ensure that we don't look at values outside our range
        {
            queueEnqueue(q, indexAbove);
            updateObject(currentObject, indexAbove, width, height);
        }

        if((indexBit < width*(height-1)) && (bitBelow > 0)) // first check to ensure that we don't look at values outside our range
        {
            queueEnqueue(q, indexBelow);
            updateObject(currentObject, indexBelow, width, height);
        }

        if((indexBit % width > 0) && (bitLeft > 0)) // first check to ensure we have an actual "left" pixel to look at
        {
            queueEnqueue(q, indexLeft);
            updateObject(currentObject, indexLeft, width, height);
        }

        if((indexBit % width < width-1) && (bitRight > 0)) // first check to ensure we have an actual "right" pixel to look at
        {
            queueEnqueue(q, indexRight);
            updateObject(currentObject, indexRight, width, height);
        }
    }
}}

void updateObject(struct Object* object, uint32_t bitIndex, uint32_t width, uint32_t height)
{
    uint16_t newY = bitIndex / width; // goes along rows/height of image
    uint16_t newX = bitIndex % width; // goes along columns/width of image

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
struct Center computeCenter(struct Object* object)
{
    struct Center cent;
    cent.id = object->id;
    cent.x = (object->minX + object->maxX)/2;
    cent.y = (object->minY + object->maxY)/2;
    cent.distanceFromCenter = abs(cent.x - IMG_WIDTH/2);

    return cent;
}

// computes center for an array of objects
uint8_t computeCenters(struct Object* objectArray, struct Center* centerArray, uint16_t length)
{
    uint8_t i = 0;
    while((objectArray[i].id != EMPTY_OBJECT_ID) && (i < length))
    {
        centerArray[i] = computeCenter(&objectArray[i]);
        i++;
    }
    return i; // num objects
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

void printObjectArray(struct Object* objArray, uint16_t length)
{
    uint16_t i = 0;
    while((i < length) && (objArray[i].id != EMPTY_OBJECT_ID))
    {
        printf("id: %i; minX: %i; maxX: %i; minY: %i; maxY: %i \n",
            objArray[i].id,
            objArray[i].minX,
            objArray[i].maxX,
            objArray[i].minY,
            objArray[i].maxY);
        i++;
    }
    printf("\n");
}

// bitLoc is the bit location. 7 for MSB, 0 for LSB, etc.
uint8_t getBitInByte(uint8_t byte, uint32_t bitLoc)
{
    uint8_t mask = 1 << bitLoc;
    uint8_t val = ((byte & mask) >> bitLoc) & 1;
    return val;
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


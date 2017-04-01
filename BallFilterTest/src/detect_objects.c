#include <stdio.h>
#include <stdint.h>
#include <stdlib.h> // for abs()
#include "detect_objects.h"
#include "algs.h"
#include "main.hpp"

void objectOverwrite(struct Object* obj, uint16_t id, uint8_t isBall, uint32_t minX, uint32_t maxX, uint32_t minY, uint32_t maxY)
{
    obj->id = id; // no object
    obj->isBall = isBall;
    obj->box[0] = minX; // goes along width/columns of image
    obj->box[2] = minY; // goes down height/rows of image
    obj->box[1] = maxX;
    obj->box[3] = maxY;
}

int32_t scanPic(struct Object* objArray, struct Queue* q, uint8_t* bitPicture)
{
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
                // start bitVal = getBitInByte(bitPicture[byteIndex], i); // data is arranged 7 6 5 4 3 2 2 1 0 for each byte.
                bitVal = bitPicture[byteIndex] << (7-i);
                bitVal = bitVal >> 7;
                // end bitVal = getBitInByte(bitPicture[byteIndex], i);

                // if bitVal == 0, do nothing and move on
                if(bitVal>0)
                {
                    objectId++;
                    uint32_t bitIndex = byteIndex*8 + i;
                    if(bitIndex < IMG_WIDTH || bitIndex >= IMG_WIDTH*(IMG_HEIGHT-1))
                    {
                        printf("gonna get an error - scanPic \n");
                    }

                    queueEnqueue(q, bitIndex); //push the bit index to the queue
                    setBitInPic(bitPicture, bitIndex, 0); // set to 0 when we enqueue. This way, objects in queue are always 0

                    if(objectId >= OBJECT_ARRAY_LENGTH)
                    {
                        return -1;
                    }
                    else
                    {
                        // our specific bit's position in its byte. using this because our bitIndex,
                        // while specifying where to access the pixel,
                        // can't be used to detect the x position of the pixel in the image
                        //uint8_t bitPos = bitIndex % 8;

                        // after the first frame, objArray holds old data. So we need to overwrite that data with what's new.

                        objectOverwrite(
                                &objArray[objectId],
                                objectId,
                                -1,                    // isBall
                                (bitIndex % IMG_WIDTH),  // box[0]
                                (bitIndex % IMG_WIDTH),  // box[1]
                                bitIndex / IMG_WIDTH,  // box[2]
                                bitIndex / IMG_WIDTH); // box[3]

                        floodFill(bitPicture, q, &objArray[objectId]);
                    }
                }
            }
            byteIndex++;
            //fourCurrent = &bitPicture[byteIndex];
        }
    }

    return objectId+1;
}

void floodFill(uint8_t* bitPicture, struct Queue* q, struct Object* currentObject)
{ 
    uint32_t head = q->head;
    uint32_t tail = q->tail;
    uint32_t numElem = q->numElem;
    uint32_t* arr    = q->arr;
    uint32_t* box = currentObject->box;

    while(numElem > 0)
    {
        if(numElem >= BUFFER_SIZE-4)
        {
            //printf("yo, your queue hit capacity\n");
            break; // ABORT
        }

        // START uint32_t indexBit = queueDequeue(q);
        uint32_t indexBit = arr[head];
        head = (head + 1) % BUFFER_SIZE;
        numElem--;
        // END uint32_t indexBit = queueDequeue(q);


        // START looking at indexAbove
        uint32_t indexCurrent = indexBit-IMG_WIDTH;
        uint8_t bitCurrent = getBitInPic(bitPicture, indexCurrent);
        if(bitCurrent > 0) // first check to ensure that we don't look at values outside our range
        {
            uint32_t tmpMock;
//            {tmpMock, tail, numElem} = optDetObj(arr, tail, numElem, indexCurrent, bitPicture, box);

            //printf("%x %x\n", tmpMock, bitPicture);
            //printf("%x\n", tmpMock);
            // START queueEnqueue(q, indexCurrent);
            arr[tail] = indexCurrent;
            tail = (tail + 1) % BUFFER_SIZE;
            numElem++;
            // END queueEnqueue(q, indexCurrent);

            // START setBitInPic(bitPicture, indexCurrent, 0);
            uint32_t byteIndex = indexCurrent >> 3; // divide by 8
            uint8_t bitNum = indexCurrent & 7; // mod 8
            bitPicture[byteIndex] = (bitPicture[byteIndex] & ~(1 << bitNum));
            // END setBitInPic(bitPicture, indexCurrent, 0);

            // START updateObject(currentObject, indexCurrent);
            uint16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
            uint16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image

            if(newX < box[0]) box[0] = newX;
            if(newX > box[1]) box[1] = newX;
            if(newY < box[2]) box[2] = newY;
            if(newY > box[3]) box[3] = newY;
            // END updateObject(currentObject, indexCurrent);
        }
        // END looking at indexAbove

        // START looking at indexBelow
        indexCurrent = indexBit+IMG_WIDTH;
        bitCurrent = getBitInPic(bitPicture, indexCurrent);
        if(bitCurrent > 0) // first check to ensure that we don't look at values outside our range
        {
            uint32_t tmpMock;
//            {tmpMock, tail, numElem} = optDetObj(arr, tail, numElem, indexCurrent, bitPicture, box);

            // START queueEnqueue(q, indexCurrent);
            arr[tail] = indexCurrent;
            tail = (tail + 1) % BUFFER_SIZE;
            numElem++;
            // END queueEnqueue(q, indexCurrent);

            // START setBitInPic(bitPicture, indexCurrent, 0);
            uint32_t byteIndex = indexCurrent >> 3;
            uint8_t bitNum = indexCurrent & 7;
            bitPicture[byteIndex] = (bitPicture[byteIndex] & ~(1 << bitNum));
            // END setBitInPic(bitPicture, indexCurrent, 0);

            // START updateObject(currentObject, indexCurrent);
            uint16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
            uint16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image

            if(newX < box[0]) box[0] = newX;
            if(newX > box[1]) box[1] = newX;
            if(newY < box[2]) box[2] = newY;
            if(newY > box[3]) box[3] = newY;
            // END updateObject(currentObject, indexCurrent);
        }
        // END looking at indexBelow

        // START looking at indexLeft
        indexCurrent  = indexBit-1;
        bitCurrent  = getBitInPic(bitPicture, indexCurrent);
        if(bitCurrent > 0) // first check to ensure we have an actual "left" pixel to look at
        {
            uint32_t tmpMock;
//            {tmpMock, tail, numElem} = optDetObj(arr, tail, numElem, indexCurrent, bitPicture, box);

            // START queueEnqueue(q, indexCurrent);
            arr[tail] = indexCurrent;
            tail = (tail + 1) % BUFFER_SIZE;
            numElem++;
            // END queueEnqueue(q, indexCurrent);

            // START setBitInPic(bitPicture, indexCurrent, 0);
            uint32_t byteIndex = indexCurrent >> 3;
            uint8_t bitNum = indexCurrent & 7;
            bitPicture[byteIndex] = (bitPicture[byteIndex] & ~(1 << bitNum));
            // END setBitInPic(bitPicture, indexCurrent, 0);

            // START updateObject(currentObject, indexCurrent);
            uint16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
            uint16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image

            if(newX < box[0]) box[0] = newX;
            if(newX > box[1]) box[1] = newX;
            if(newY < box[2]) box[2] = newY;
            if(newY > box[3]) box[3] = newY;
            // END updateObject(currentObject, indexCurrent);
        }
        // END looking at indexLeft

        // START looking at indexRight
        indexCurrent = indexBit+1;
        bitCurrent = getBitInPic(bitPicture, indexCurrent);
        if(bitCurrent > 0) // first check to ensure we have an actual "right" pixel to look at
        {
            uint32_t tmpMock;
//            {tmpMock, tail, numElem} = optDetObj(arr, tail, numElem, indexCurrent, bitPicture, box);

            // START queueEnqueue(q, indexCurrent);
            arr[tail] = indexCurrent;
            tail = (tail + 1) % BUFFER_SIZE;
            numElem++;
            // END queueEnqueue(q, indexCurrent);

            // START setBitInPic(bitPicture, indexCurrent, 0);
            uint32_t byteIndex = indexCurrent >> 3;
            uint8_t bitNum = indexCurrent & 7;
            bitPicture[byteIndex] = (bitPicture[byteIndex] & ~(1 << bitNum));
            // END setBitInPic(bitPicture, indexCurrent, 0);

            // START updateObject(currentObject, indexCurrent);
            uint16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
            uint16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image

            if(newX < box[0]) box[0] = newX;
            if(newX > box[1]) box[1] = newX;
            if(newY < box[2]) box[2] = newY;
            if(newY > box[3]) box[3] = newY;
            // END updateObject(currentObject, indexCurrent);
        }
        // END looking at indexRight
    }

    q->head = head;
    q->tail = tail;
    q->numElem = numElem;
}

void updateObject(struct Object* object, uint32_t bitIndex)
{
    // our specific bit's position in its byte. using this because our bitIndex,
    // while specifying where to access the pixel,
    // can't be used to detect the x position of the pixel in the image
    //uint32_t bitPos = bitIndex % 8;


    uint16_t newY = bitIndex / IMG_WIDTH; // goes along rows/height of image
    //uint16_t newX = (bitIndex % IMG_WIDTH) + 7 - 2*bitPos; // theoretically, this converts from bitIndex to the pixelPosition
    uint16_t newX = (bitIndex % IMG_WIDTH); // goes along columns/width of image

    if(newX < object->box[0])
    {
        object->box[0] = newX;
    }

    if(newX > object->box[1])
    {
        object->box[1] = newX;
    }

    if(newY < object->box[2])
    {
        object->box[2] = newY;
    }

    if(newY > object->box[3])
    {
        object->box[3] = newY;
    }
}

// computes the center of a particular object
void computeCenter(struct Object* object)
{
    object->centX = (object->box[0] + object->box[1])/2;
    object->centY = (object->box[2] + object->box[3])/2;
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
        if(objectArray[i].box[1] - objectArray[i].box[0] < 5 ||
            objectArray[i].box[3] - objectArray[i].box[2] < 5)
        {
            objectArray[i].isBall = 0;
        }

        // if the object is on the edge of the image
        // (where edge is defined as 2 pixel width surrounding edge)
        else if(objectArray[i].box[0] < 2 || objectArray[i].box[2] < 2 ||
            objectArray[i].box[1] > IMG_WIDTH-3 || objectArray[i].box[3] > IMG_HEIGHT-3)
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
    obj->box[0] = 0; // goes along width/columns of image
    obj->box[2] = 0; // goes down height/rows of image
    obj->box[1] = 0;
    obj->box[3] = 0;
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
        objArray[i].box[0] = 0;
        objArray[i].box[1] = 0;
        objArray[i].box[2] = 0;
        objArray[i].box[3] = 0;
        objArray[i].centX = 0;
        objArray[i].centY = 0;
        objArray[i].distanceFromCenter = 0;
    }
}

// pack the center data to be used for sending over uart
void packObjects(
    struct Object* objArray,
    uint8_t* buffer,
    int32_t numObjects)
{
    for(int i = 0; i < numObjects; i++)
    {
        // these labels might not be correct, due to endianess...?????
        uint16_t centXLower = objArray[i].centX & 0xFF;
        uint16_t centXUpper = objArray[i].centX >> 8;
        uint16_t centYLower = objArray[i].centY & 0xFF;
        uint16_t centYUpper = objArray[i].centY >> 8;
        uint16_t minXLower  = objArray[i].box[0] & 0xFF;
        uint16_t minXUpper  = objArray[i].box[0] >> 8;
        uint16_t maxXLower  = objArray[i].box[1] & 0xFF;
        uint16_t maxXUpper  = objArray[i].box[1] >> 8;
        uint16_t minYLower  = objArray[i].box[2] & 0xFF;
        uint16_t minYUpper  = objArray[i].box[2] >> 8;
        uint16_t maxYLower  = objArray[i].box[3] & 0xFF;
        uint16_t maxYUpper  = objArray[i].box[3] >> 8;

        buffer[i*12] = centXLower;
        buffer[i*12 + 1] = centXUpper;
        buffer[i*12 + 2] = centYLower;
        buffer[i*12 + 3] = centYUpper;
        buffer[i*12 + 4] = minXLower;
        buffer[i*12 + 5] = minXUpper;
        buffer[i*12 + 6] = maxXLower;
        buffer[i*12 + 7] = maxXUpper;
        buffer[i*12 + 8] = minYLower;
        buffer[i*12 + 9] = minYUpper;
        buffer[i*12 + 10] = maxYLower;
        buffer[i*12 + 11] = maxYUpper;
    }

    if(numObjects < OBJECT_ARRAY_LENGTH)
    {
        buffer[numObjects*12] = 0xFF;
        buffer[numObjects*12+1] = 0xFF;
    }
}

int32_t unpackObjects(
    struct Object* objArray,
    uint8_t* buffer,
    uint16_t bufferLength)
{
    for(int i = 1; i < bufferLength; i+=12) // i = 1 because I think there's a 0 byte at the front
    {
        uint8_t centXLower = buffer[i]; // each of these is flipped from what I would expect
        uint8_t centXUpper = buffer[i+1];
        uint8_t centYLower = buffer[i+2];
        uint8_t centYUpper = buffer[i+3];
        uint8_t xMinLower  = buffer[i+4];
        uint8_t xMinUpper  = buffer[i+5];
        uint8_t xMaxLower  = buffer[i+6];
        uint8_t xMaxUpper  = buffer[i+7];
        uint8_t yMinLower  = buffer[i+8];
        uint8_t yMinUpper  = buffer[i+9];
        uint8_t yMaxLower  = buffer[i+10];
        uint8_t yMaxUpper  = buffer[i+11];

        uint16_t centX = (centXUpper << 8) | centXLower;
        uint16_t centY = (centYUpper << 8) | centYLower;
        uint16_t xMin = (xMinUpper << 8) | xMinLower;
        uint16_t xMax = (xMaxUpper << 8) | xMaxLower;
        uint16_t yMin = (yMinUpper << 8) | yMinLower;
        uint16_t yMax = (yMaxUpper << 8) | yMaxLower;
        if(centX == 0xFFFF) // that's our cue -- we've hit our last object
        {
            return i/12+1; // num objects
            break;
        }

        objArray[i/12].centX = centX;
        objArray[i/12].centY = centY;
        objArray[i/12].box[0] = xMin;
        objArray[i/12].box[1] = xMax;
        objArray[i/12].box[2] = yMin;
        objArray[i/12].box[3] = yMax;

    }
    return bufferLength/12; // num objects
}



int32_t unpackCenters(
    struct Object* objArray,
    uint8_t* buffer,
    uint16_t bufferLength)
{
    for(int i = 0; i < bufferLength; i+=4)
    {
        uint8_t xLower = buffer[i];
        uint8_t xUpper = buffer[i+1];
        uint8_t yLower = buffer[i+2];
        uint8_t yUpper = buffer[i+3];

        uint16_t centX = (xUpper << 8) | xLower;
        uint16_t centY = (yUpper << 8) | yLower;

        objArray[i/4].centX = centX;
        objArray[i/4].centY = centY;
    }
    return bufferLength/4; // num objects
}


void printObjectArray(struct Object* objArray, uint16_t length)
{
    for(int i = 0; i < length; i++)
    {
        printf("id: %i; box[0]: %i; box[1]: %i; box[2]: %i; box[3]: %i; centX: %i; centY: %i \n",
            objArray[i].id,
            objArray[i].box[0],
            objArray[i].box[1],
            objArray[i].box[2],
            objArray[i].box[3],
            objArray[i].centX,
            objArray[i].centY);
        i++;
    }
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
/*uint8_t getBitInByte(uint8_t byte, uint32_t bitLoc)
{
    byte = byte << (7-bitLoc);
    byte = byte >> 7;

    return byte;
}*/

// given a certain bitIndex, get that bit (stored in a byte).
// so a bitIndex of 4 will get the 4th bit.
uint8_t getBitInPic(uint8_t* bitPicture, uint32_t bitIndex)
{

    uint8_t val; // return value
    uint32_t byteIndex = bitIndex/8;
    //uint32_t bitNum = bitIndex % 8;
    uint32_t bitNum = bitIndex & 0b111;

    // val = getBitInByte(bitPicture[byteIndex], 7-bitNum); // this is for when bytes were arranged 0 1 2 3 4 5 6 7 instead of 7 6 ...

    // start val = getBitInByte(bitPicture[byteIndex], bitNum);
    val = bitPicture[byteIndex] << (7-bitNum);
    val = val >> 7;
    // end val = getBitInByte(bitPicture[byteIndex], bitNum);

    return val;
}


// bitLoc is the bit location. 7 for MSB, 0 for LSB, etc.
//int8_t setBitInByte(uint8_t* unsafe byte, uint8_t bitLoc, uint8_t bitVal)
//{ unsafe {
//    /*if(bitVal > 1 || bitLoc > 7)
//    {
//        return FUNC_ERROR;
//    }*/
//    //http://stackoverflow.com/questions/47981/how-do-you-set-clear-and-toggle-a-single-bit-in-c-c
//    *byte = (*byte & ~(1 << bitLoc)) | (bitVal << bitLoc);
//
//    return 0;
//}}

// given a certain bitIndex, set that bit to either 0 or 1.
inline int8_t setBitInPic(uint8_t* bitPicture, uint32_t bitIndex, uint8_t val)
{
    /*if(val > 1 || bitIndex >= IMG_WIDTH*IMG_HEIGHT)
    {
        return FUNC_ERROR;
    }*/
    uint32_t byteIndex = bitIndex/8;
    //uint8_t bitNum = bitIndex % 8;
    uint8_t bitNum = bitIndex & 0b111;

    //setBitInByte(&bitPicture[byteIndex], 7-bitNum, val); // this is for when bytes were arranged 0 1 2 3 4 5 6 7 instead of 7 6 ...


    // START setBitInByte(&bitPicture[byteIndex], bitNum, val);
    bitPicture[byteIndex] = (bitPicture[byteIndex] & ~(1 << bitNum)) | (val << bitNum);
    // END setBitInByte(&bitPicture[byteIndex], bitNum, val);

    return 0;
}


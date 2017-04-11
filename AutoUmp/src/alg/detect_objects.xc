#include <stdio.h>
#include <stdint.h>
#include <stdlib.h> // for abs()
#include "detect_objects.h"
#include "floodFillAlg.h"
#include "objectTrackerAlg.h" // for round(x)

void objectOverwrite(struct Object* obj, uint16_t id, int8_t isBall, int32_t minX, int32_t maxX, int32_t minY, int32_t maxY)
{
    obj->id = id; // no object
    obj->isBall = isBall;
    obj->box[0] = minX; // goes along width/columns of image
    obj->box[2] = minY; // goes down height/rows of image
    obj->box[1] = maxX;
    obj->box[3] = maxY;
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
}}

void floodFill(uint8_t* unsafe bitPicture, struct Queue* q, struct Object* currentObject)
{ unsafe {
    uint32_t head = q->head;
    uint32_t tail = q->tail;
    uint32_t numElem = q->numElem;
    uint32_t* unsafe arr    = q->arr;
    int32_t* unsafe box = currentObject->box;

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
            uint32_t byteIndex = indexCurrent >> 3;
            uint8_t bitNum = indexCurrent & 7;
            bitPicture[byteIndex] = (bitPicture[byteIndex] & ~(1 << bitNum));
            // END setBitInPic(bitPicture, indexCurrent, 0);

            // START updateObject(currentObject, indexCurrent);
            int16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
            int16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image

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
            int16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
            int16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image

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
            int16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
            int16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image

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
            int16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
            int16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image

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
}}

void updateObject(struct Object* object, uint32_t bitIndex)
{
    // our specific bit's position in its byte. using this because our bitIndex,
    // while specifying where to access the pixel,
    // can't be used to detect the x position of the pixel in the image
    //uint32_t bitPos = bitIndex % 8;


    int16_t newY = bitIndex / IMG_WIDTH; // goes along rows/height of image
    //uint16_t newX = (bitIndex % IMG_WIDTH) + 7 - 2*bitPos; // theoretically, this converts from bitIndex to the pixelPosition
    int16_t newX = (bitIndex % IMG_WIDTH); // goes along columns/width of image

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

// computes center for an array of objects
void computeCenters(struct Object* objectArray, int32_t length)
{
    for (int i = 0; i < length; i++)
    {
        objectArray[i].centX = (objectArray[i].box[0] + objectArray[i].box[1])/2;
        objectArray[i].centY = (objectArray[i].box[2] + objectArray[i].box[3])/2;
        objectArray[i].distanceFromCenter = abs(objectArray[i].centX - IMG_WIDTH/2);
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
    uint8_t* unsafe buffer,
    int32_t numObjects)
{ unsafe {

    buffer[0] = 0xFA;
    buffer = &buffer[1];

    #define NB 9 // num bytes per object
    for(int i = 0; i < numObjects; i++)
    {
        uint16_t minXLower  = objArray[i].box[0] & 0xFF;
        uint16_t minXUpper  = objArray[i].box[0] >> 8;
        uint16_t maxXLower  = objArray[i].box[1] & 0xFF;
        uint16_t maxXUpper  = objArray[i].box[1] >> 8;
        uint16_t minYLower  = objArray[i].box[2] & 0xFF;
        uint16_t minYUpper  = objArray[i].box[2] >> 8;
        uint16_t maxYLower  = objArray[i].box[3] & 0xFF;
        uint16_t maxYUpper  = objArray[i].box[3] >> 8;
        uint8_t  markVal    = objArray[i].isBall;

        buffer[i*NB] = minXLower;
        buffer[i*NB + 1] = minXUpper;
        buffer[i*NB + 2] = maxXLower;
        buffer[i*NB + 3] = maxXUpper;
        buffer[i*NB + 4] = minYLower;
        buffer[i*NB + 5] = minYUpper;
        buffer[i*NB + 6] = maxYLower;
        buffer[i*NB + 7] = maxYUpper;
        buffer[i*NB + 8] = markVal;
    }

    if(numObjects < OBJECT_ARRAY_LENGTH)
    {
        buffer[numObjects*NB] = 0xFF;
        buffer[numObjects*NB+1] = 0xFF;
    }
}}

void packIntersection(
        float intersection,
        uint8_t* unsafe buffer
        )
{ unsafe {
    uint16_t inter = round(intersection);

    uint16_t interUpper = inter >> 8;
    uint16_t interLower = inter & 0xFF;

    buffer[0] = 0xFB;
    buffer[1] = interUpper;
    buffer[2] = interLower;
}}

uint16_t unpackIntersection(
        uint8_t* unsafe buffer)
{ unsafe {
    uint16_t interUpper = buffer[1];
    uint16_t interLower = buffer[2];

    uint16_t intersection = (interUpper << 8) | interLower;

    return intersection;
}}

// given a certain bitIndex, get that bit (stored in a byte).
// so a bitIndex of 4 will get the 4th bit.
uint8_t getBitInPic(uint8_t* unsafe bitPicture, uint32_t bitIndex)
{ unsafe {

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
}}

// given a certain bitIndex, set that bit to either 0 or 1.
inline int8_t setBitInPic(uint8_t* unsafe bitPicture, uint32_t bitIndex, uint8_t val)
{ unsafe {
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
}}


int32_t mergeObjects(struct Object* unsafe objArray, int32_t length)
{ unsafe {

    //http://stackoverflow.com/questions/12284025/whats-the-best-way-to-merge-a-set-of-rectangles-in-an-image
    #define EXPAND 2
    //int foundIntersection = 0;

    //do
    //{
        // for each object
        int i;
        for(i = 0; i < length; i++)
        {
            if(objArray[i].isBall == 0) // merged
            {
                continue;
            }
            // compare with every other object
            // (comparisons below i+1 have already been checked)
            int j;
            for(j = 0; j < length; j++)
            {
                if((objArray[j].isBall == 0) || (i == j))
                //if((objArray[j].isBall == 0))
                {
                   continue;
                }

                // get and expand bounds for both objects
                int32_t* unsafe box1 = objArray[i].box;
                int32_t* unsafe box2 = objArray[j].box;

                box1[0] = box1[0] - EXPAND;
                box1[1] = box1[1] + EXPAND;
                box1[2] = box1[2] - EXPAND;
                box1[3] = box1[3] + EXPAND;

                box2[0] = box2[0] - EXPAND;
                box2[1] = box2[1] + EXPAND;
                box2[2] = box2[2] - EXPAND;
                box2[3] = box2[3] + EXPAND;

                // this checks for non-overlap
                // http://stackoverflow.com/questions/306316/determine-if-two-rectangles-overlap-each-other

                if((box1[0] > box2[1]) || (box1[1] < box2[0]) ||
                   (box1[2] > box2[3]) || (box1[3] < box2[2]))
                {
                    // no overlap
                    box2[0] = box2[0] + EXPAND;
                    box2[1] = box2[1] - EXPAND;
                    box2[2] = box2[2] + EXPAND;
                    box2[3] = box2[3] - EXPAND;

                    box1[0] = box1[0] + EXPAND;
                    box1[1] = box1[1] - EXPAND;
                    box1[2] = box1[2] + EXPAND;
                    box1[3] = box1[3] - EXPAND;

                    continue;
                }
                else
                {
                    //foundIntersection = 1;
                    // we overlap! merge objects.
                    objArray[j].isBall = 0; // merge 2 (j) into 1 (i)
                    if(box2[0] < box1[0]) box1[0] = box2[0];
                    if(box2[1] > box1[1]) box1[1] = box2[1];
                    if(box2[2] < box1[2]) box1[2] = box2[2];
                    if(box2[3] > box1[3]) box1[3] = box2[3];

                    box2[0] = box2[0] + EXPAND;
                    box2[1] = box2[1] - EXPAND;
                    box2[2] = box2[2] + EXPAND;
                    box2[3] = box2[3] - EXPAND;

                    box1[0] = box1[0] + EXPAND;
                    box1[1] = box1[1] - EXPAND;
                    box1[2] = box1[2] + EXPAND;
                    box1[3] = box1[3] - EXPAND;
                }
            }
        }
    //} while(foundIntersection);

    return 0;
}}

// filter out anything less than a 3x3 square
int32_t filterLarge(struct Object* unsafe objArray, int32_t length)
{ unsafe {
    int32_t numLarge = 0;
    int i;
    for(i = 0; i < length; i++)
    {
        int32_t isBall = objArray[i].isBall;
        if(isBall == 0)
        {
            // already not a ball, move on
            continue;
        }

        int32_t* box = objArray[i].box;
        if(((box[1] - box[0]) > 2) &&
           ((box[3] - box[2]) > 2))
        {
            objArray[i].isBall = 1;
            numLarge++;
        }
        else
        {
            objArray[i].isBall = 0;
        }
    }
    return numLarge;
}}

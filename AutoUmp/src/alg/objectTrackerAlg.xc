#include "objectTrackerAlg.h"
#include "interfaces.h"
#include "floodFillAlg.h"
#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void ObjectTracker(
    interface ObjectTrackerToGameInter client ot2g,
    interface FloodFillToObjectInter server tile0FF2OT[4],
    interface FloodFillToObjectInter server tile1FF2OT[4])
{ unsafe {
    int loopCount = 0;
    uint8_t buffer[320*240/8];
    struct Object objArrayTmpLeft[OBJECT_ARRAY_LENGTH];
    struct Object objArrayTmpRight[OBJECT_ARRAY_LENGTH];

    struct ObjectArray objArrayLeft;
    struct ObjectArray objArrayRight;

    uint32_t intersectionLeft; // y val, at x = 160, from left camera
    uint32_t intersectionRight; // y val, at x = 160, from left camera
    uint32_t intersectFlagLeft = 0;
    uint32_t intersectFlagRight = 0;


    // by virtue of the fact that we only are tracking one object in each.
    struct ObjectTrack trackLeft;
    struct ObjectTrack trackRight;

    ObjectTrackInit(&trackLeft,  0);
    ObjectTrackInit(&trackRight, 1);


    while(1==1)
    {
        select
        {
            case tile0FF2OT[int i].sendObjects(struct Object objArray[], uint32_t numObjects, uint8_t bitBuffer[], uint32_t m, int id):
                if (i != 1) break;


                if(i % 2 == 0) // left camera
                {
                    for(int i = 0; i < OBJECT_ARRAY_LENGTH; i++)
                    {
                        objArrayTmpLeft[i] = objArray[i];
                    }

                    ObjectArrayInit((struct ObjectArray* unsafe)&objArrayLeft);

                    //reduces objArray to objArrayLeft, which just has objects in the middle for this frame.
                    filterToMiddle(objArrayTmpLeft, &objArrayLeft, numObjects);

                    //select the object that best matches the current track/a ball
                    //int result = updateTrack(&trackLeft, &objArrayLeft);

                    //if result == 0, then track updated fine (either we add a new object to it or count a dead frame)
                    //else if result == 1, then object has been missing for 3 frames and we need to calulate intersection and reinit track
                        // calculateIntersection()
                        // ObjectTrackInit()
                        // intersectFlagLeft = 1;
                }
                else // right camera
                {
                    for(int i = 0; i < 250; i++)
                    {
                        objArrayTmpRight[i] = objArray[i];
                    }

                    ObjectArrayInit((struct ObjectArray* unsafe)&objArrayRight);
                    filterToMiddle(objArrayTmpRight, &objArrayRight, numObjects);
                }

                // send data over UART

                loopCount++;
                if(loopCount % 1 == 0)
                {
                    memset(buffer, 0, OBJECT_ARRAY_LENGTH*9);
                    packObjects(objArrayTmpRight, buffer, numObjects);

                    ot2g.forwardBuffer(buffer, OBJECT_ARRAY_LENGTH*9);
                    //btInter.sendBuffer(buffer, 250*9);

                }
                break;

            case tile1FF2OT[int i].sendObjects(struct Object objArray[], uint32_t numObjects, uint8_t bitBuffer[], uint32_t m, int id):
                /*if(i % 2 == 0) // left camera
                {

                }
                else // right camera
                {

                }*/
                break;
        }

        /*if(intersectFlagLeft && intersectFlagRight)
        {
            kzoneLocation = getKZoneLocation();
            intersectFlagLeft = 0;
            intersectFlagRight = 0;
            ot2g.sendKZoneLocation(kzoneLocation);
        }*/
    }
}}

void ObjectArrayInit(struct ObjectArray* unsafe array)
{ unsafe {
    array->objectNum = 0;
}}

void ObjectTrackInit(struct ObjectTrack* unsafe track, uint32_t id)
{ unsafe {
    track->id = id;
    track->totalFramesCount = 0;
    track->head = 0;
    track->deadFrames = 0;
}}


// Return -1 if error
int ObjectArrayAdd(struct ObjectArray* unsafe array, int topLx, int topLy, int botRx, int botRy)
{ unsafe {
    if (array->objectNum >= OBJECTS_NUM) return -1;

    array->objects[array->objectNum].box[0] = topLx;
    array->objects[array->objectNum].box[1] = topLy;
    array->objects[array->objectNum].box[2] = botRx;
    array->objects[array->objectNum].box[3] = botRy;

    array->objects[array->objectNum].centX = (topLx + botRx) / 2;
    array->objects[array->objectNum].centY = (topLy + botRy) / 2;

    array->objectNum++;

    return 0;
}}

// filter out any object that's not in the middle of the image
// (i.e., a quarter of the image away from the center in every direction)
int filterToMiddle(struct Object* unsafe objArray, struct ObjectArray* unsafe newObjArray, int32_t length)
{ unsafe {
    for(int i = 0; i < length; i++)
    {
        if(objArray[i].isBall == 0)
        {
            continue;
        }

        int32_t centX = (objArray[i].box[0] + objArray[i].box[1]) / 2;
        if(centX < IMG_WIDTH/4 || centX > 3*IMG_WIDTH/4)
        {
            objArray[i].isBall = 3;
            continue;
        }

        int32_t centY = (objArray[i].box[2] + objArray[i].box[3]) / 2;
        if(centY < IMG_HEIGHT/4 || centY > 3*IMG_HEIGHT/4)
        {
            objArray[i].isBall = 3;
            continue;
        }

        // if you get here, that means it's in the middle.
        // weird indexing of "box" here because we're switching
        // from minX, maxX, minY, maxY convention to topLx, topLy, botRx, botRy
        ObjectArrayAdd(newObjArray, objArray[i].box[0], objArray[i].box[2], objArray[i].box[1], objArray[i].box[3]);

    }

    return 0;
}}

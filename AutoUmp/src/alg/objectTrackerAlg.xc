#include "objectTrackerAlg.h"
#include "interfaces.h"
#include "floodFillAlg.h"
#include "detect_objects.h"
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
    uint8_t interBuffer[3] = {0xFB, 0, 0};
    struct Object objArrayTmpLeft[OBJECT_ARRAY_LENGTH];
    struct Object objArrayTmpRight[OBJECT_ARRAY_LENGTH];

    struct ObjectArray objArrayLeft;
    struct ObjectArray objArrayRight;

    float intersectionLeft = 0.0; // y val, at x = 160, from left camera
    float intersectionRight = 0.0; // y val, at x = 160, from left camera
    uint32_t intersectFlagLeft = 0;
    uint32_t intersectFlagRight = 0;
    uint32_t skipLeft = 0;
    uint32_t skipRight = 0;


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
                if(i % 2 == 0) // left camera
                {
                    if(skipLeft)
                    {
                        skipLeft--;
                    }
                    else
                    {
                        intersectionLeft = 0.0;
                    }

                    for(int i = 0; i < OBJECT_ARRAY_LENGTH; i++)
                    {
                        objArrayTmpLeft[i] = objArray[i];
                    }

                    //filterLarge(objArrayTmpLeft, numObjects);

                    ObjectArrayInit((struct ObjectArray* unsafe)&objArrayLeft);

                    //reduces objArray to objArrayLeft, which just has objects in the middle for this frame.
                    filterToMiddle(objArrayTmpLeft, &objArrayLeft, numObjects);

                    //select the object that best matches the current track/a ball
                    int result = updateTrack(&trackLeft, &objArrayLeft, 0);

                    //if result == 0, then track updated fine (either we add a new object to it or count a dead frame)
                    if(result == 1) // time to calculate the intersection!
                    {
                        intersectionLeft =  calculateIntersection(&trackLeft);
                        //packIntersection(intersectionLeft, interBuffer);
                        //uint16_t inter = unpackIntersection(interBuffer);
                        ObjectTrackInit(&trackLeft, 0);
                        intersectFlagLeft = 1;
                        skipLeft = FRAME_SKIP;

                        /*if(skipRight)
                        {
                            printf("found intersection 0! Left Cam: %.3f, Right Cam: %.3f\n", intersectionLeft, intersectionRight);
                        }*/
                    }
                }
                else // right camera
                {
                    if(skipRight) skipRight--;
                    else
                    {
                        intersectionRight = 0.0;
                    }

                    for(int i = 0; i < 250; i++)
                    {
                        objArrayTmpRight[i] = objArray[i];
                    }

                    //filterLarge(objArrayTmpRight, numObjects);

                    ObjectArrayInit((struct ObjectArray* unsafe)&objArrayRight);
                    filterToMiddle(objArrayTmpRight, &objArrayRight, numObjects);

                    int result = updateTrack(&trackRight, &objArrayRight, 0);

                    if(result == 1)
                    {
                        intersectionRight = calculateIntersection(&trackRight);
                        packIntersection(intersectionRight, interBuffer);
                        ObjectTrackInit(&trackRight, 0);
                        intersectFlagRight = 1;
                        skipRight = FRAME_SKIP;

                        /*if(skipLeft)
                        {
                            printf("found intersection 1! Left Cam: %.3f, Right Cam: %.3f\n", intersectionLeft, intersectionRight);
                        }*/
                    }
                }

                // send data over UART
                if (i != 1) break;

                loopCount++;
                if(loopCount % 1 == 0)
                {
                    memset(buffer, 0, OBJECT_ARRAY_LENGTH*9);
                    packObjects(objArrayTmpRight, buffer, numObjects);

                    ot2g.forwardBuffer(buffer, OBJECT_ARRAY_LENGTH*9);

                    ot2g.forwardIntersection(interBuffer, 3);
                    interBuffer[1] = 0;
                    interBuffer[2] = 0;

                    //btInter.sendBuffer(buffer, 250*9);
                }
                break;

            case tile1FF2OT[int i].sendObjects(struct Object objArray[], uint32_t numObjects, uint8_t bitBuffer[], uint32_t m, int id):
                if(i % 2 == 0) // left camera
                {
                    if(skipLeft)
                    {
                        skipLeft--;
                    }
                    else
                    {
                        intersectionLeft = 0.0;
                    }

                    for(int i = 0; i < OBJECT_ARRAY_LENGTH; i++)
                    {
                        objArrayTmpLeft[i] = objArray[i];
                    }

                    filterLarge(objArrayTmpLeft, numObjects);

                    ObjectArrayInit((struct ObjectArray* unsafe)&objArrayLeft);

                    //reduces objArray to objArrayLeft, which just has objects in the middle for this frame.
                    filterToMiddle(objArrayTmpLeft, &objArrayLeft, numObjects);

                    //select the object that best matches the current track/a ball
                    int result = updateTrack(&trackLeft, &objArrayLeft, 0);

                    //if result == 0, then track updated fine (either we add a new object to it or count a dead frame)
                    if(result == 1) // time to calculate the intersection!
                    {
                        intersectionLeft =  calculateIntersection(&trackLeft);
                        packIntersection(intersectionLeft, interBuffer);
                        //uint16_t inter = unpackIntersection(interBuffer);
                        //printf("%f %i\n", intersectionLeft, inter);
                        ObjectTrackInit(&trackLeft, 0);
                        intersectFlagLeft = 1;
                        skipLeft = FRAME_SKIP;

                        /*if(skipRight)
                        {
                            //send
                            printf("found intersection 2! Left Cam: %.3f, Right Cam: %.3f\n", intersectionLeft, intersectionRight);
                        }*/
                    }
                }
                else // right camera
                {
                    if(skipRight)
                    {
                        skipRight--;
                    }
                    else
                    {
                        intersectionRight = 0.0;
                    }

                    for(int i = 0; i < 250; i++)
                    {
                        objArrayTmpRight[i] = objArray[i];
                    }

                    filterLarge(objArrayTmpRight, numObjects);

                    ObjectArrayInit((struct ObjectArray* unsafe)&objArrayRight);
                    filterToMiddle(objArrayTmpRight, &objArrayRight, numObjects);

                    int result = updateTrack(&trackRight, &objArrayRight, 0);

                    if(result == 1)
                    {
                        intersectionRight = calculateIntersection(&trackRight);
                        packIntersection(intersectionRight, interBuffer);
                        ObjectTrackInit(&trackRight, 0);
                        intersectFlagRight = 1;
                        skipRight = FRAME_SKIP;

                        /*if(skipLeft)
                        {
                            printf("found intersection 3! Left Cam: %.3f, Right Cam: %.3f\n", intersectionLeft, intersectionRight);
                        }*/
                    }
                }
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
    track->lastFrame = -1;
}}


// Return -1 if error
int ObjectArrayAdd(struct ObjectArray* unsafe array, int32_t topLx, int32_t topLy, int32_t botRx, int32_t botRy)
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


int updateTrack(struct ObjectTrack* unsafe track, struct ObjectArray* unsafe objectArray, uint32_t trackID)
{ unsafe {
    // check for empty array
    if(objectArray->objectNum == 0)
    {
        track->deadFrames++;
    }
    else if(objectArray->objectNum == 1)
    {
        if(track->totalFramesCount == 0)
        {
            addToHistory(track, &objectArray->objects[0]);
        }
        else
        {
            // check: is it a valid object?
            // valid is defined as: moved to the right, and less than 20 pixels change in y
            if(isValid(&track->history[track->lastFrame], &objectArray->objects[0]))
            {
                // add to history
                addToHistory(track, &objectArray->objects[0]);
            }
            else
            {
                track->deadFrames++;
            }
        }
    }
    else { // more than one object in objectArray
        struct FoundObject bestObject;
        struct FoundObject tmpObject;
        int32_t bestObjectIndex = -1;

        // find the best object
        for(int i = 0; i < objectArray->objectNum; i++)
        {
            tmpObject = objectArray->objects[i];
            if(isValid(&track->history[track->lastFrame], &tmpObject))
            {
                if(bestObjectIndex == -1)
                {
                    bestObject = tmpObject;
                    bestObjectIndex = i;
                }
                else
                {
                    if(tmpObject.centX > bestObject.centX)
                    {
                        bestObject = tmpObject;
                        bestObjectIndex = i;
                    }
                }
            }
        }

        if(bestObjectIndex == -1) track->deadFrames++;
        else
        {
            addToHistory(track, &bestObject);
        }
    }

    if(track->deadFrames > 2)
    {
        ObjectTrackInit(track, trackID);
    }

    // decide if we need to calculate the intersection
    int32_t idx = track->lastFrame - 1;
    int32_t twoFramesAgo = (idx % OBJECTS_HISTORY + OBJECTS_HISTORY) % OBJECTS_HISTORY;
    if(track->lastFrame >= 0 &&
        track->history[track->lastFrame].centX > IMG_WIDTH/2 &&
        track->totalFramesCount >= 2 &&
        track->history[twoFramesAgo].centX <= IMG_WIDTH/2 &&
        track->history[track->lastFrame].centX - track->history[twoFramesAgo].centX > 0)
    {
        return 1;
    }

    return 0;
}}

int32_t isValid(struct FoundObject* unsafe obj1, struct FoundObject* unsafe obj2)
{ unsafe {
    if((obj2->centX - obj1->centX > 0) &&
        ((obj2->centY - obj1->centY < 20) || (obj1->centY - obj2->centY < 20)))
    {
        return 1;
    }
    else return 0;
}}

int32_t addToHistory(struct ObjectTrack* unsafe track, struct FoundObject* unsafe obj)
{ unsafe {
    track->history[track->head] = *obj;
    if(track->totalFramesCount < OBJECTS_HISTORY) track->totalFramesCount++;
    track->head = (track->head + 1) % OBJECTS_HISTORY;
    track->lastFrame = (track->lastFrame + 1) % OBJECTS_HISTORY;

    return 0;
}}

float calculateIntersection(struct ObjectTrack* unsafe track)
{ unsafe {
    int32_t lastFrameIndex = track->lastFrame;
    int32_t twoFramesAgoIndex = ((lastFrameIndex - 1) % OBJECTS_HISTORY + OBJECTS_HISTORY) % OBJECTS_HISTORY;
    struct FoundObject f0 = track->history[twoFramesAgoIndex];
    struct FoundObject f1 = track->history[lastFrameIndex];

    float interX = (double)IMG_WIDTH / 2.0;
    float m = ((float)f1.centY - (float)f0.centY) / ((float)f1.centX - f0.centX);
    float interY = (float)f0.centY + m * (interX - (float)f0.centX);

    return interY;
}}

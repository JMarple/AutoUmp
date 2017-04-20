#include "objectTrackerAlg.h"
#include "interfaces.h"
#include "floodFillAlg.h"
#include "detect_objects.h"
#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

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

    uint32_t waitingLeft = 0;
    uint32_t waitingRight = 0;


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
                    if(skipLeft) skipLeft--;
                    else intersectionLeft = 0.0;

                    if(waitingLeft) waitingLeft--;

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

                    if(result == 1) // time to calculate the intersection!
                    {
                        intersectionLeft =  calculateIntersection(&trackLeft);
                        //packIntersection(intersectionLeft, interBuffer);
                        ObjectTrackInit(&trackLeft, 0);
                        skipLeft = FRAME_SKIP;
                        waitingLeft = FRAME_WAIT;

                        uint8_t dbg[13];
                        snprintf(dbg, 13, " LI: %03.3f \n", intersectionLeft);
                        ot2g.forwardBuffer(dbg, 13);
                    }
                }
                else // right camera
                {
                    if(skipRight) skipRight--;
                    else intersectionRight = 0.0;

                    if(waitingRight) waitingRight--;

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
                        skipRight = FRAME_SKIP;
                        waitingRight = FRAME_WAIT;

                        uint8_t dbg[13];
                        snprintf(dbg, 13, " RI: %03.3f \n", intersectionRight);
                        ot2g.forwardBuffer(dbg, 13);
                    }
                }

                // send data over UART
                if (i != 0) break;

                loopCount++;
                if(loopCount % 2 == 0)
                {
/*                    memset(buffer, 0, OBJECT_ARRAY_LENGTH*9);
                    packObjects(objArrayTmpRight, buffer, numObjects);

                    ot2g.forwardBuffer(buffer, OBJECT_ARRAY_LENGTH*9);

                    ot2g.forwardIntersection(interBuffer, 3);
                    interBuffer[1] = 0;
                    interBuffer[2] = 0;
*/
                    // forward bitBuffer
 /*                   memset(buffer, 0, 320*240/8);
                    for(int j = 0; j < 320*240/8; j++)
                    {
                        buffer[j] = bitBuffer[j];
                    }
                    ot2g.forwardImg(buffer, 320*240/8); */
                }
                break;

            case tile1FF2OT[int i].sendObjects(struct Object objArray[], uint32_t numObjects, uint8_t bitBuffer[], uint32_t m, int id):
                if(i % 2 == 0) // left camera
                {
                    if(skipLeft) skipLeft--;
                    else intersectionLeft = 0.0;

                    if(waitingLeft) waitingLeft--;

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
                        ObjectTrackInit(&trackLeft, 0);
                        skipLeft = FRAME_SKIP;
                        waitingLeft = FRAME_WAIT;

                        uint8_t dbg[13];
                        snprintf(dbg, 13, " LI: %03.3f \n", intersectionLeft);
                        ot2g.forwardBuffer(dbg, 13);
                    }
                }
                else // right camera
                {
                    if(skipRight) skipRight--;
                    else intersectionRight = 0.0;

                    if(waitingRight) waitingRight--;

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
                        //packIntersection(intersectionRight, interBuffer);
                        ObjectTrackInit(&trackRight, 0);
                        skipRight = FRAME_SKIP;
                        waitingRight = FRAME_WAIT;

                        uint8_t dbg[13];
                        snprintf(dbg, 13, " RI: %03.3f \n", intersectionRight);
                        ot2g.forwardBuffer(dbg, 13);
                    }
                }
                break;
        }

        if(waitingLeft && waitingRight)
        {
            //printf("found intersection! Left Cam: %.3f, Right Cam: %.3f\n", intersectionLeft, intersectionRight);
            struct Point pitch = kZoneLocation(intersectionLeft, intersectionRight);
            uint16_t lIntersect = round(intersectionLeft);
            uint16_t rIntersect = round(intersectionRight);
            //printf("x: %.3f, y: %.3f, coord(%.3f, %.3f)\n", pitch.x, pitch.y, intersectionLeft, intersectionRight);

            ot2g.sendPitch(pitch, lIntersect, rIntersect);
            waitingLeft  = 0;
            waitingRight = 0;
        }
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
        if(centY < IMG_HEIGHT/8 || centY > 7*IMG_HEIGHT/8)
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

float deg2rad(float deg)
{
    return deg * PI / 180.0;
}

struct Point kZoneLocation(float intersectionLeft, float intersectionRight)
{
    float cameraSeparationIn = 13.25; // inches, for protoype board
    float fieldOfViewDeg = 80.0; // degrees
    float resolution = 240.0; // pixels
    float camHeightM = 0.070; // meters. for protoype board, 25.0mm + 40.0mm.

    float inToM = 0.0254; // inches to meters multiplication factor
    float mToIn = 1.0/inToM;

    float cameraSeparationM = cameraSeparationIn * inToM;

    struct Point camLeft;
    camLeft.x = 0 - cameraSeparationM/2;
    camLeft.y = camHeightM;

    float offsetRadLeft = deg2rad(35.0); // (180-80)/2 - 15
    float offsetRadRight = deg2rad(35.0); // (180-80)/2 - 15
    float eachPixelRad = deg2rad(fieldOfViewDeg / resolution);

    float omega_L = offsetRadLeft + (resolution - intersectionLeft) * eachPixelRad; // radians
    float omega_R = offsetRadRight + (intersectionRight) * eachPixelRad; // radians
    float omega_B = PI - omega_L - omega_R;

    float L_side = cameraSeparationM * sin(omega_R) / sin(omega_B);

    struct Point result;
    result.x = camLeft.x + L_side * cos(omega_L);
    result.y = camLeft.y + L_side * sin(omega_L);

    // convert to inches
    result.x = result.x * mToIn;
    result.y = result.y * mToIn;

    result.x = result.x + 24;
    if(result.x > 48) result.x = 48;
    if(result.x < 0) result.x = 0;

    return result;
}

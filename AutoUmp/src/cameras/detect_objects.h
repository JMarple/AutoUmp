/*
 * default_objects.h
 *
 *  Created on: Mar 6, 2017
 *      Author: tbadams45
 */
#ifndef DETECT_OBJECTS_H_
#define DETECT_OBJECTS_H_

#include <stdint.h>
#include "queue.h"

#define EMPTY_OBJECT_ID 65535 // highest value of uint16_t bit.
#define FUNC_ERROR -1

// represents an arbitrary object detected in our image
struct Object
{
    uint8_t  isBall; // -1 = not checked, 0 = no, 1 = yes
    uint16_t id; // id representing object
    int32_t minX, maxX, minY, maxY; // lower/uppper bounds of object
};


// describes the center of the object with the given
struct Center
{
    int32_t x, y, id;
    int32_t distanceFromCenter; // absolute value. in x direction.
};

struct CenterPair
{
    struct Center cents[2];
    int32_t totalDistanceFromCenter; // absolute value. x direction. summed of both centers
};

void objectInit(struct Object* obj);

uint16_t scanPic(
    struct Object* objArray,
    struct Queue* q,
    uint8_t* unsafe bitPicture,
    uint32_t width,
    uint32_t height);

void floodFill(
    uint8_t* unsafe bitPicture,
    struct Queue* q,
    struct Object* currentObject,
    uint32_t width,
    uint32_t height);

void detectObjects(
    uint8_t* row_above,
    uint8_t* row_current,
    uint8_t* row_below,
    uint32_t length,
    uint8_t*  id,
    uint8_t rowNum,
    struct Object* objArray);

void detectObjectsPic(
    uint8_t* picture,
    uint32_t width,
    uint32_t height,
    struct Object* objArray);

void updateObject(
    struct Object* object,
    uint32_t bitIndex,
    uint32_t width,
    uint32_t height);

struct Center computeCenter(
    struct Object* object);

uint8_t computeCenters(
    struct Object* objectArray,
    struct Center* centerArray,
    uint16_t length);

int32_t filterBalls(
    struct Object* objectArray,
    uint16_t length);

void getTwoCenters(
    struct Center* centerPair,
    struct Object* objectArray,
    struct Center* centerArray,
    uint16_t length);

void printObjectArray(
    struct Object* objArray,
    uint16_t length);

uint8_t getBitInPic(
    uint8_t* unsafe bitPicture,
    uint32_t bitIndex);

uint8_t getBitInByte(
    uint8_t byte,
    uint32_t bitLoc);

int8_t setBitInPic(
    uint8_t* unsafe bitPicture,
    uint32_t bitIndex,
    uint8_t val);

int8_t setBitInByte(
    uint8_t* unsafe byte,
    uint8_t bitLoc,
    uint8_t bitVal);


#endif /* DETECT_OBJECTS_H_ */

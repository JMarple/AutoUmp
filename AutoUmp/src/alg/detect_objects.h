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
    int8_t  isBall; // -1 = not checked, 0 = no, 1 = yes
    uint16_t id; // id representing object
    int32_t box[4]; // box[0]: minX. box[1]: maxX. box[2]: minY. box[3]: maxY
    uint16_t centX, centY;
    uint16_t distanceFromCenter;
};


// describes the center of the object with the given
struct Center
{
    uint16_t x, y, id;
    uint16_t distanceFromCenter; // absolute value. in x direction.
};

struct CenterPair
{
    struct Center cents[2];
    int32_t totalDistanceFromCenter; // absolute value. x direction. summed of both centers
};

void objectOverwrite(
        struct Object* obj,
        uint16_t id,
        int8_t isBall,
        int32_t minX,
        int32_t maxX,
        int32_t minY,
        int32_t maxY);

int32_t scanPic(
    struct Object* objArray,
    struct Queue* q,
    uint8_t* unsafe bitPicture);

void floodFill(
    uint8_t* unsafe bitPicture,
    struct Queue* q,
    struct Object* currentObject);

void updateObject(
    struct Object* object,
    uint32_t bitIndex);

void computeCenters(
    struct Object* objectArray,
    int32_t length);

void getTwoCenters(
    struct Center* centerPair,
    struct Object* objectArray,
    struct Center* centerArray,
    uint16_t length);

void initObjectArray(
    struct Object* objArray,
    uint16_t length);

void packObjects(
    struct Object* objArray,
    uint8_t* unsafe buffer,
    int32_t numObjects);

uint8_t getBitInPic(
    uint8_t* unsafe bitPicture,
    uint32_t bitIndex);

inline int8_t setBitInPic(
    uint8_t* unsafe bitPicture,
    uint32_t bitIndex,
    uint8_t val);

int32_t mergeObjects(struct Object* unsafe objArray, int32_t length);

#endif /* DETECT_OBJECTS_H_ */

#ifndef __ALGS_H__
#define __ALGS_H__

#define IMG_WIDTH 320
#define IMG_HEIGHT 240
#define OBJECT_ARRAY_LENGTH 250

#include "detect_objects.h"
#include "queue.h"

struct DenoiseRowLU2
{
    uint8_t top[16];
};

struct DenoiseRowLU
{
    struct DenoiseRowLU2 bot[16];
};

struct DenoiseLookup
{
    struct DenoiseRowLU cur[64];
};

interface MasterToFloodFillInter
{
    void sendBitBuffer(uint8_t bitBuffer[], uint32_t n);
};

interface FloodFillToObjectInter
{
    void sendObjects();
};

void FloodFill(
    uint8_t* unsafe bitBuffer,
    struct Object* objArray,
    struct Queue* queue,
    uint8_t* unsafe objInfo,
    struct DenoiseLookup* unsafe lu);

void FloodFillThread(
    chanend stream,
    interface MasterToFloodFillInter server mtff,
    struct Object* objArray,
    struct Queue* queue,
    uint8_t* unsafe objInfo,
    uint8_t* unsafe bitBuffer,
    struct DenoiseLookup* unsafe lu );

void DenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot,
    struct DenoiseLookup* unsafe tbl);

uint8_t inline DenoiseAndFlipByte(
    uint8_t top,
    uint8_t left,
    uint8_t cur,
    uint8_t right,
    uint8_t bot);

void JustinDenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot);


void DenoiseInitLookup(struct DenoiseLookup* unsafe lu);

#endif

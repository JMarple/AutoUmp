#ifndef __ALGS_H__
#define __ALGS_H__

#define IMG_WIDTH 320
#define IMG_HEIGHT 240
#define OBJECT_ARRAY_LENGTH 250

#include "detect_objects.h"
#include "queue.h"
#include "interfaces.h"

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

#define FLOOD_FILL_CORES 8

int FloodFillMain(
    uint8_t* unsafe bitBuffer,
    struct Object* objArray,
    struct Queue* queue,
    struct DenoiseLookup* unsafe lu);

void FloodFillThread(
    interface MasterToFloodFillInter server mtff,
    interface FloodFillToObjectInter client ff2ot,
    struct DenoiseLookup* unsafe lu, int num);

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


void DenoiseInitLookup(struct DenoiseLookup* unsafe lu);

#endif

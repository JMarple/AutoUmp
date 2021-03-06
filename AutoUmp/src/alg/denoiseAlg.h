#ifndef __DENOISE_ALG_H
#define __DENOISE_ALG_H

#include <stdint.h>

#define OBJECT_ARRAY_LENGTH 250

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

void DenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot,
    struct DenoiseLookup* unsafe lu);

void DenoiseInitLookup(struct DenoiseLookup* unsafe lu);

#endif

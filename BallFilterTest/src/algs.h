#ifndef __FLOOD_FILL_ALG_H
#define __FLOOD_FILL_ALG_H

#include<stdint.h>

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
    uint32_t* top,
    uint32_t* cur,
    uint32_t* bot,
    struct DenoiseLookup* lu);

#endif

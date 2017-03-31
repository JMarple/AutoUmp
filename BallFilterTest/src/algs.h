#ifndef ALGS_H
#define ALGS_H

#define OBJECT_ARRAY_LENGTH 250

void DenoiseRow(
    uint32_t* top,
    uint32_t* cur,
    uint32_t* bot,
    struct DenoiseLookup* lu);


#endif

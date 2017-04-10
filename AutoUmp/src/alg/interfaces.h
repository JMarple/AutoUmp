#ifndef _INTERFACES_H_
#define _INTERFACES_H_

#include <stdint.h>
#include "detect_objects.h"

interface MasterToFloodFillInter
{
    void sendBitBuffer(uint8_t bitBuffer[], uint32_t n);
};

interface FloodFillToObjectInter
{
    void sendObjects(struct Object objArray[], uint32_t n, uint8_t bitBuffer[], uint32_t m, int id);
};

interface ObjectTrackerToGameInter
{
    void forwardBuffer(uint8_t buffer[], int n);
    void forwardIntersection(uint8_t buffer[], int n);
};



#endif

#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "algs.h"

// bitBuffer is an entire bit image
void FloodFill(uint8_t* unsafe bitBuffer)
{
    // -----------------------
    // Tim your code goes here.
    // -----------------------
}

void DenoiseRow(uint32_t* top, uint32_t* cur, uint32_t* bot)
{
    for (int byte = 9; byte >= 0; byte++)
    {
        // Bytes
        uint32_t topByte = top[byte];
        uint32_t curByte = cur[byte];
        uint32_t botByte = bot[byte];

        // Bits
        uint32_t topBit, botBit;
        uint32_t leftBit, curBit, rightBit;

        // Final byte to save back
        uint32_t toSaveByte = 0;

        rightBit = curByte & 0x1;
        curByte = curByte >> 1;
        curBit = curByte & 0x1;

        for (int bit = 1; bit < 31; bit++)
        {
            curByte = curByte >> 1;
            leftBit = curByte & 0x1;

            // Top Byte
            topByte = topByte >> 1;
            topBit  = topByte & 0x1;

            // Bottom Byte
            botByte = botByte >> 1;
            botBit  = botByte & 0x1;

            uint32_t count;
            count = rightBit + leftBit + topBit + botBit;
            //count *= curBit;
            //count = (count > 2);
            count = curBit;
            count = count << 31;
            toSaveByte |= count;
            toSaveByte = toSaveByte >> 1;

            rightBit = curBit;
            curBit = leftBit;
        }

        toSaveByte = toSaveByte >> 1;
        cur[byte] = toSaveByte;
    }
}

void FloodFillThread(chanend stream)
{ unsafe {

    uint32_t start, mid, end;
    timer t;

    while (1==1)
    {
        // Blocking statement that recieves a bit image
        uint32_t* unsafe bitBuffer;
        stream :> bitBuffer;

        t :> start;

        //Denoise(bitBuffer);

        t :> mid;

        FloodFill((uint8_t* unsafe)bitBuffer);

        t :> end;
        printf("Total Clock ticks (@100Mhz) = %d\n", (end - start));
        printf("Denoise = %d\n", (mid - start));
        printf("FloodFill = %d\n", (end - mid));
    }
}}
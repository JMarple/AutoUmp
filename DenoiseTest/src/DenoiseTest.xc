#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <stdint.h>

void ov07740_denoise(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot)
{ unsafe {
    for (int byte = 9; byte >= 0; byte--)
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
}}

int main()
{ unsafe {
    printf("Testing Denoise Function\n");

    uint32_t img[240*40/4];

    for (int y = 0; y < 240; y++)
    {
        if (y > 1 && y < 239)
        {
            ov07740_denoise(
                &(img[10*(y-2)]),
                &(img[10*(y-1)]),
                &(img[10*(y)]));
        }
    }

    return 0;
}}
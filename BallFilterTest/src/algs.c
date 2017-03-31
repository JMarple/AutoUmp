#include "algs.h"

void DenoiseRow(
    uint32_t* top,
    uint32_t* cur,
    uint32_t* bot,
    struct DenoiseLookup* lu)
{

    // init
    uint32_t topWord  = 0;
    uint32_t curWord  = 0;
    uint32_t botWord  = 0;
    uint32_t topBit   = 0;
    uint32_t curBit   = 0;
    uint32_t botBit   = 0;
    uint32_t rightBit = 0;
    uint32_t leftBit  = 0;
    uint32_t result   = 0;
    uint32_t outWord  = 0;

    for (int i = 0; i < 10; i++)
    {
        //printf("Row %d, %x %x %x\n", i, top[i], cur[i], bot[i]);
    }

    for (int i = 0; i < 320; i+=4)
    {
        int idx = i / 32;
        if (i % 32 == 0)
        {
            //printf("Loading with idx = %d\n", idx);
            curWord |= (cur[idx] << 1);
            topWord = top[idx];
            botWord = bot[idx];
            //printf("Loaded = %x %x %x\n", curWord, topWord, botWord);
        }
        else if (i % 32 == 4)
        {
            uint32_t tmp = (cur[idx] & 0x80000000) >> 3;
            curWord |= tmp;
        }

        uint32_t res = lu->cur[curWord & 0x3F].bot[botWord & 0xF].top[topWord & 0xF];
        //printf("c=%d %x, %x %x %x\n", i, res, curWord& 0x3F, botWord& 0xF, topWord& 0xF);

        res <<= 28;
        outWord |= res;

        // Save outWord
        if (i % 32 == 28)
        {
            cur[idx] = outWord;
            //printf("Out = %x\n", outWord);
        }

        outWord >>= 4;
        curWord >>= 4;
        topWord >>= 4;
	}

}

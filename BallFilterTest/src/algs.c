#include "algs.h"

//#include "detect_objects.h"
//#include "queue.h"

static void _DenoiseInitElement(uint8_t* output, uint8_t cur, uint8_t bot, uint8_t top)
{
    uint8_t result = 0;

    int i;
    for (i = 0; i < 4; i++)
    {
        int count = 0;
        int curBit = (cur & 0b000010) > 0;

        count += (cur & 0b000001);
        count += (cur & 0b000100) > 0;
        count += (top & 0b0001);
        count += (bot & 0b0001);

        //printf("count=%d ", count);
        if (count > 2) result |= ((1*curBit) << i);

        top >>= 1;
        bot >>= 1;
        cur >>= 1;
    }

    //printf("%x %x %x, %x\n", cur, bot, top, result);
    *output = result;
}

void DenoiseInitLookup(struct DenoiseLookup* lu)
{
    int cur, bot, top;
    for (cur = 0; cur < 64; cur++)
    {
        for (bot = 0; bot < 16; bot++)
        {
            for (top = 0; top < 16; top++)
            {
                _DenoiseInitElement(
                    &lu->cur[cur].bot[bot].top[top],
                    cur, bot, top);
            }
        }
    }
}

void DenoiseRowOld(
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

    int i, k;
    for (i = 0; i < 10; i++)
    {
        topWord = top[i];
        curWord = cur[i];
        botWord = bot[i];
        for (k = 0; k < 32; k++)
        {
            rightBit = curWord & 0x1;

            // compute result
            result = topBit + botBit + leftBit + rightBit;
            result = ((result > 2) * curBit) << 31;

            outWord |= result;

            // shift words
            curWord = curWord >> 1;

            if(k == 0 && i != 0)
            {
                cur[i-1] = outWord;
                outWord = 0;
            }

            outWord = outWord >> 1;

            // shift bits
            leftBit = curBit;
            curBit  = rightBit;

            topBit  = topWord & 0x1;
            botBit  = botWord & 0x1;

            // shift words
            topWord = topWord >> 1;
            botWord = botWord >> 1;
        }
    }
    cur[9] = outWord;
}

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

    int i;
    for (i = 0; i < 10; i++)
    {
        //printf("Row %d, %x %x %x\n", i, top[i], cur[i], bot[i]);
    }

    for (i = 0; i < 320; i+=4)
    {
        int idx = i / 32;
        if (i % 32 == 0)
        {
            curWord |= (cur[idx] << 1);
            topWord = top[idx];
            botWord = bot[idx];
        }
        else if (i % 32 == 4)
        {
            uint32_t tmp = (cur[idx] & 0x80000000) >> 3;
            curWord |= tmp;
        }
        else if (i % 32 == 8 && (idx+1) < 10)
        {
            uint32_t tmp = (cur[idx+1] & 0b1) << 25;
            curWord |= tmp;
        }

        uint32_t res = lu->cur[curWord & 0x3F].bot[botWord & 0xF].top[topWord & 0xF];

        res <<= 28;
        outWord |= res;

        // Save outWord
        if (i % 32 == 28)
        {
            cur[idx] = outWord;
        }

        outWord >>= 4;
        curWord >>= 4;
        botWord >>= 4;
        topWord >>= 4;
	}
}

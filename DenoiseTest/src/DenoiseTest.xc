#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <stdint.h>
// you're never going to get the top, bottom rows in current
void DenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot)
{ unsafe {

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
        topWord = top[i];
        curWord = cur[i];
        botWord = bot[i];
        for (int k = 0; k < 32; k++)
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
}}


void printStuff(uint32_t r)
{
    for (int i = 0; i < 32; i++)
    {
        if (i % 8 == 0) printf(" ");
        printf("%d", (r >> i) & 0x1);
    }
}


int main()
{ unsafe {

    printf("Testing Denoise Function\n");

    uint8_t x[40*3];

    x[0] = 0x4;
    x[1] = 0x2;
    x[2] = 0x3;
    x[3] = 0x0;

    x[40] = 0b01110;
    x[41] = 0x0;
    x[42] = 0x0;
    x[43] = 0x0;

    x[80] = 0x4;
    x[81] = 0x2;
    x[82] = 0x3;
    x[83] = 0x0;

    printStuff(((uint32_t*)x)[0]);
    printf("\n");
    printStuff(((uint32_t*)x)[10]);
    printf("\n");
    printStuff(((uint32_t*)x)[20]);
    printf("\n");

    uint32_t* unsafe top = &((uint32_t*)x)[0];
    uint32_t* unsafe cur = &((uint32_t*)x)[10];
    uint32_t* unsafe bot = &((uint32_t*)x)[20];

    DenoiseRow(top, cur, bot);

    printf("Result = \n");
    printStuff(((uint32_t*)x)[10]);
    printf("\n");



    // 0x4 0x3 0x2 0x1
    // ^32...........^0

    printf("\n");

    /*uint32_t img[240*40/4];

    for (int y = 0; y < 240; y++)
    {
        if (y > 1 && y < 239)
        {
            ov07740_denoise(
                &(img[10*(y-2)]),
                &(img[10*(y-1)]),
                &(img[10*(y)]));
        }
    }*/

    return 0;
}}

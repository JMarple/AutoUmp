#include "algs.h"
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
    struct DenoiseLookup* lu = (struct DenoiseLookup*) malloc(sizeof(struct DenoiseLookup));
    if (lu == 0) printf("Lookup table out of memory!");
    DenoiseInitLookup(lu);

    uint32_t top[10], top2[10];
    uint32_t cur[10], cur2[10];
    uint32_t bot[10], bot2[10];

    srand(time(NULL));
    memset(top, 0, 10*sizeof(uint32_t));
    memset(top2, 0, 10*sizeof(uint32_t));
    memset(cur, 0, 10*sizeof(uint32_t));
    memset(cur2, 0, 10*sizeof(uint32_t));
    memset(bot, 0, 10*sizeof(uint32_t));
    memset(bot2, 0, 10*sizeof(uint32_t));

    int i;
    for (i = 0; i < 10; i++)
    {
        top[i] = top2[i] = rand();
        cur[i] = cur2[i] = rand();
        bot[i] = bot2[i] = rand();
    }

    /*top[1] = top2[1] = 0x50281f76;
    cur[1] = cur2[1] = 0x3e6191b2;
    bot[1] = bot2[1] = 0x58f7ae22;*/

    /*for (i = 0; i < 10; i++)
    {
        top[i] = top2[i] = 0x00000000;
        cur[i] = cur2[i] = 0xFFFFFFFF;
        bot[i] = bot2[i] = 0xFFFFFFFF;
    }*/

    printf("Top=");
    for (i = 0; i < 10; i++)
        printf("%08x ", top[i]);
    printf("\n");

    printf("Cur=");
    for (i = 0; i < 10; i++)
        printf("%08x ", cur[i]);
    printf("\n");

    printf("Bot=");
    for (i = 0; i < 10; i++)
        printf("%08x ", bot[i]);
    printf("\n\n");

    DenoiseRowOld(top, cur, bot, lu);
    DenoiseRow(top2,  cur2, bot2, lu);

    for (i = 0; i < 10; i++)
        printf("%08x ", cur[i]);
    printf("\n");

    for (i = 0; i < 10; i++)
        printf("%08x ", cur2[i]);
    printf("\n");

    for (i = 0; i < 10; i++)
    {
        if (cur[i] != cur2[i])
            printf("%d is not correct!\n", i);
    }

    return 0;
}

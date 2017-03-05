#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "algs.h"

uint8_t lookup32[32] = {
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 1, 0, 0, 0, 1,
        0, 0, 0, 1, 0, 0, 0, 1,
        0, 1, 1, 1, 0, 1, 1, 1};

// bitBuffer is an entire bit image
void FloodFill(uint8_t* unsafe bitBuffer)
{ unsafe {


    for (int i = 2; i < IMG_HEIGHT; i++)
    {
        DenoiseRow(
                &bitBuffer[(i-2)*IMG_WIDTH],
                &bitBuffer[(i-1)*IMG_WIDTH],
                &bitBuffer[i*IMG_WIDTH]);
    }
}}

void FloodFillThread(chanend stream)
{ unsafe {

    uint32_t start, end;
    timer t;

    while (1==1)
    {
        // Blocking statement that recieves a bit image
        uint32_t* unsafe bitBuffer;
        stream :> bitBuffer;

        t :> start;

        FloodFill((uint8_t* unsafe)bitBuffer);

        t :> end;
        printf("Clock ticks (@100Mhz) = %d\n", (end - start));
    }
}}

// you're never going to get the top, bottom rows in current
void DenoiseRow(
    uint8_t* unsafe top,
    uint8_t* unsafe cur,
    uint8_t* unsafe bot)
{ unsafe {

    // deal with leftmost byte in row.
    cur[0] = DenoiseAndFlipByte(top[0], 0, cur[0], cur[1], bot[0]);

    for (int byte = 1; byte < IMG_WIDTH-1; byte++)
    {
        cur[byte] = DenoiseAndFlipByte(top[byte], cur[byte-1], cur[byte], cur[byte+1], bot[byte]);
    }

    // deal with rightmost byte in row.
    cur[IMG_WIDTH-1] = DenoiseAndFlipByte(top[IMG_WIDTH-1], cur[IMG_WIDTH-2], cur[IMG_WIDTH-1], 0, bot[IMG_WIDTH-1]);
}}

// assuming top, current, bottom, right have latest bit in msb.
// left has earliest bit in msb.
//
uint8_t inline DenoiseAndFlipByte(
    uint8_t top,
    uint8_t left,
    uint8_t cur,
    uint8_t right,
    uint8_t bot)
{

    // bits
    uint8_t topBit, botBit;
    uint8_t leftBit, curBit, rightBit;

    // final byte to save back
    uint8_t toSaveByte = 0;

    // number of white pixels around current
    uint8_t count = 0;

    // deal with the first bit.
    topBit = top & 0x1;
    top = top >> 1;

    botBit = bot & 0x1;
    bot = bot >> 1;

    rightBit = left & 0x1; // counterintuitive, but this is the orientation: 0 1 2 3 4 5 6 7 ||| 15 14 13 12 11 10 9 8

    curBit = cur & 0x1;
    cur = cur >> 1;

    leftBit = cur & 0x1;
    cur = cur >> 1;

    //data = (something & 0x11)
    //data |= (topbit << 4)
    //data |= (botbit << 5)
    //result = lookup[data]

    count = topBit + botBit + leftBit + rightBit;
    count = (count > 2);

    toSaveByte |= count << 7;

    // deal with middle bytes
    for (int i = 1; i < 7; i++)
    {
        topBit = top & 0x1;
        top = top >> 1;

        botBit = bot & 0x1;
        bot = bot >> 1;

        rightBit = curBit;
        curBit = leftBit;
        leftBit = cur & 0x1;
        cur = cur >> 1;

        count = topBit + botBit + leftBit + rightBit;
        count = (count > 2);

        toSaveByte |= count << (7 - i);
    }

    // deal with the last bit
    topBit = top & 0x1;
    botBit = bot & 0x1;

    rightBit = curBit;
    curBit = leftBit;
    leftBit = right & 0x1; // counterintuitive, but this is the orientation: 15 14 13 12 11 10 9 8 ||| 23 22 21 20 19 18 17 16

    count = topBit + botBit + leftBit + rightBit;
    count = (count > 2);

    toSaveByte |= count;

    return toSaveByte;
}


/*
 *  Used to test DenoiseAndFlipByte:
 *
 *  uint8_t byte = DenoiseAndFlipByte(255, 128, 255, 1, 255);
    printf("all 1s: %x\n", byte);

    byte = DenoiseAndFlipByte(0, 127, 0, 254, 0);
    printf("all 0s: %x\n", byte);

    byte = DenoiseAndFlipByte(170, 0, 170, 0, 170);
    printf("alternating, start 1: %x\n", byte);

    byte = DenoiseAndFlipByte(85, 0, 85, 0, 85);
    printf("alternating, start 0: %x\n", byte);

    byte = DenoiseAndFlipByte(85, 1, 85, 0, 85);
    printf("should be 0x80: %x\n", byte);

    byte = DenoiseAndFlipByte(170, 0, 170, 1, 170);
    printf("should be 1: %x\n", byte);

    byte = DenoiseAndFlipByte(170, 0, 254, 0, 170);
    printf("should be 0xaa: %x\n", byte);
 *
 *
 */


void JustinDenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot)
{ unsafe {
    for (int byte = 9; byte >= 0; byte++) // why 9 to 0, and not 0 to 9? Probably little endian/big endian thing
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

            // now determine if we should save it or not


            //count *= curBit;
            //count = (count > 2);
            count = curBit;
            count = count << 31;
            toSaveByte |= count;
            toSaveByte = toSaveByte >> 1;

            rightBit = curBit;
            curBit = leftBit;
        }

        toSaveByte = toSaveByte >> 1; // ?
        cur[byte] = toSaveByte;
    }
}}

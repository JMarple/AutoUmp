#ifndef __ALGS_H__
#define __ALGS_H__

#define IMG_WIDTH 320
#define IMG_HEIGHT 240

void FloodFillThread(chanend stream);
void DenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot);

uint8_t inline DenoiseAndFlipByte(
    uint8_t top,
    uint8_t left,
    uint8_t cur,
    uint8_t right,
    uint8_t bot);

void JustinDenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot);

#endif

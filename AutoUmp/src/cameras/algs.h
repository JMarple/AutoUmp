#ifndef __ALGS_H__
#define __ALGS_H__

void FloodFillThread(chanend stream);
void DenoiseRow(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot);

#endif

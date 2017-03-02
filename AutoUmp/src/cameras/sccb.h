#ifndef __SCCB_H__
#define __SCCB_H__

#include <stdint.h>

void sccb_init(port sioc, port siod, clock siob);
int sccb_wr(uint8_t addr, int reg, int val, port sioc, port siod);
int sccb_rd(uint8_t addr, int reg, port sioc, port siod);

#endif
